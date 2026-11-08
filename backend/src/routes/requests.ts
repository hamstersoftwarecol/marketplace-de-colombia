import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { requireAuth, optionalAuth } from '../middleware/auth.js';
import type { Bindings, HelpRequest, Proposal } from '../types/index.js';

const requests = new Hono<{ Bindings: Bindings }>();

// ---- Schemas ----

const createRequestSchema = z.object({
  category_id: z.string().optional(),
  title: z.string().min(5).max(200),
  description: z.string().min(20).max(3000),
  budget: z.number().positive().optional(),
  city_id: z.string().optional(),
  neighborhood: z.string().optional(),
  lat: z.number().optional(),
  lng: z.number().optional(),
});

const updateRequestSchema = z.object({
  title: z.string().min(5).max(200).optional(),
  description: z.string().min(20).max(3000).optional(),
  status: z.enum(['open', 'in_progress', 'resolved']).optional(),
  budget: z.number().positive().optional(),
});

const createProposalSchema = z.object({
  message: z.string().min(10).max(1000),
  price: z.number().positive().optional(),
});

const requestsQuerySchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  category_id: z.string().optional(),
  city_id: z.string().optional(),
});

// ---- Routes ----

/** GET /requests */
requests.get('/', zValidator('query', requestsQuerySchema), async (c) => {
  const q = c.req.valid('query');
  const conditions: string[] = ["status = 'open'"];
  const binds: (string | number)[] = [];

  if (q.cursor) {
    conditions.push('created_at < ?');
    binds.push(q.cursor);
  }
  if (q.category_id) {
    conditions.push('category_id = ?');
    binds.push(q.category_id);
  }
  if (q.city_id) {
    conditions.push('city_id = ?');
    binds.push(q.city_id);
  }

  binds.push(q.limit + 1);

  const result = await c.env.DB.prepare(
    `SELECT * FROM help_requests WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC LIMIT ?`
  )
    .bind(...binds)
    .all<HelpRequest>();

  const rows = result.results ?? [];
  const hasMore = rows.length > q.limit;
  const items = hasMore ? rows.slice(0, q.limit) : rows;
  const nextCursor = hasMore ? items[items.length - 1]?.created_at ?? null : null;

  return c.json({ success: true, data: items, meta: { limit: q.limit, nextCursor } });
});

/** POST /requests */
requests.post('/', optionalAuth, zValidator('json', createRequestSchema), async (c) => {
  const userId = c.get('userId') || 'user-prov-1';
  const body = c.req.valid('json');

  const id = crypto.randomUUID();
  const now = new Date().toISOString();
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

  await c.env.DB.prepare(
    `INSERT INTO help_requests
       (id, user_id, category_id, title, description, budget, city_id, neighborhood, lat, lng, expires_at, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  )
    .bind(
      id, userId,
      body.category_id ?? null,
      body.title, body.description,
      body.budget ?? null,
      body.city_id ?? null,
      body.neighborhood ?? null,
      body.lat ?? null,
      body.lng ?? null,
      expiresAt, now
    )
    .run();

  const req = await c.env.DB.prepare('SELECT * FROM help_requests WHERE id = ?')
    .bind(id)
    .first<HelpRequest>();

  return c.json({ success: true, data: req }, 201);
});

/** GET /requests/:id */
requests.get('/:id', async (c) => {
  const id = c.req.param('id');

  const req = await c.env.DB.prepare('SELECT * FROM help_requests WHERE id = ?')
    .bind(id)
    .first<HelpRequest>();
  if (!req) return c.json({ success: false, error: 'Request not found' }, 404);

  const proposals = await c.env.DB.prepare(
    'SELECT * FROM proposals WHERE request_id = ? ORDER BY created_at ASC'
  )
    .bind(id)
    .all<Proposal>();

  return c.json({ success: true, data: { ...req, proposals: proposals.results ?? [] } });
});

/** PUT /requests/:id */
requests.put('/:id', requireAuth, zValidator('json', updateRequestSchema), async (c) => {
  const id = c.req.param('id');
  const userId = c.get('userId');
  const body = c.req.valid('json');

  const req = await c.env.DB.prepare('SELECT * FROM help_requests WHERE id = ?')
    .bind(id)
    .first<HelpRequest>();
  if (!req) return c.json({ success: false, error: 'Request not found' }, 404);
  if (req.user_id !== userId) return c.json({ success: false, error: 'Forbidden' }, 403);

  const fields: string[] = [];
  const vals: (string | number | null)[] = [];

  if (body.title !== undefined) { fields.push('title = ?'); vals.push(body.title); }
  if (body.description !== undefined) { fields.push('description = ?'); vals.push(body.description); }
  if (body.status !== undefined) { fields.push('status = ?'); vals.push(body.status); }
  if (body.budget !== undefined) { fields.push('budget = ?'); vals.push(body.budget); }

  if (!fields.length) return c.json({ success: false, error: 'No fields to update' }, 400);

  vals.push(id);
  await c.env.DB.prepare(`UPDATE help_requests SET ${fields.join(', ')} WHERE id = ?`)
    .bind(...vals)
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM help_requests WHERE id = ?')
    .bind(id)
    .first<HelpRequest>();

  return c.json({ success: true, data: updated });
});

/** POST /requests/:id/proposals */
requests.post('/:id/proposals', requireAuth, zValidator('json', createProposalSchema), async (c) => {
  const requestId = c.req.param('id');
  const userId = c.get('userId');
  const body = c.req.valid('json');

  const req = await c.env.DB.prepare('SELECT * FROM help_requests WHERE id = ?')
    .bind(requestId)
    .first<HelpRequest>();
  if (!req) return c.json({ success: false, error: 'Request not found' }, 404);
  if (req.status !== 'open') return c.json({ success: false, error: 'Request is not open' }, 400);
  if (req.user_id === userId) return c.json({ success: false, error: 'Cannot propose on own request' }, 400);

  const id = crypto.randomUUID();
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    'INSERT INTO proposals (id, request_id, user_id, message, price, created_at) VALUES (?, ?, ?, ?, ?, ?)'
  )
    .bind(id, requestId, userId, body.message, body.price ?? null, now)
    .run();

  const proposal = await c.env.DB.prepare('SELECT * FROM proposals WHERE id = ?')
    .bind(id)
    .first<Proposal>();

  return c.json({ success: true, data: proposal }, 201);
});

export default requests;
