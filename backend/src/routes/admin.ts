import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/auth.js';
import type { Bindings, Listing, Report, User } from '../types/index.js';

const admin = new Hono<{ Bindings: Bindings }>();

// All admin routes require auth + admin role
admin.use('*', requireAuth, requireAdmin);

// ---- Routes ----

/** GET /admin/stats */
admin.get('/stats', async (c) => {
  const [users, listings, pendingListings, reports, openRequests] = await Promise.all([
    c.env.DB.prepare('SELECT COUNT(*) AS cnt FROM users').first<{ cnt: number }>(),
    c.env.DB.prepare('SELECT COUNT(*) AS cnt FROM listings').first<{ cnt: number }>(),
    c.env.DB.prepare("SELECT COUNT(*) AS cnt FROM listings WHERE status = 'pending'").first<{ cnt: number }>(),
    c.env.DB.prepare("SELECT COUNT(*) AS cnt FROM reports WHERE status = 'pending'").first<{ cnt: number }>(),
    c.env.DB.prepare("SELECT COUNT(*) AS cnt FROM help_requests WHERE status = 'open'").first<{ cnt: number }>(),
  ]);

  return c.json({
    success: true,
    data: {
      totalUsers: users?.cnt ?? 0,
      totalListings: listings?.cnt ?? 0,
      pendingListings: pendingListings?.cnt ?? 0,
      pendingReports: reports?.cnt ?? 0,
      openRequests: openRequests?.cnt ?? 0,
    },
  });
});

/** GET /admin/listings/pending */
admin.get('/listings/pending', async (c) => {
  const result = await c.env.DB.prepare(
    "SELECT l.*, u.name AS user_name, u.email AS user_email FROM listings l JOIN users u ON u.id = l.user_id WHERE l.status = 'pending' ORDER BY l.created_at ASC LIMIT 50"
  ).all<Listing & { user_name: string; user_email: string }>();
  return c.json({ success: true, data: result.results ?? [] });
});

/** PUT /admin/listings/:id/approve */
admin.put('/listings/:id/approve', async (c) => {
  const id = c.req.param('id');
  await c.env.DB.prepare(
    "UPDATE listings SET status = 'active', updated_at = ? WHERE id = ?"
  ).bind(new Date().toISOString(), id).run();
  return c.json({ success: true, data: null });
});

/** PUT /admin/listings/:id/reject */
admin.put(
  '/listings/:id/reject',
  zValidator('json', z.object({ reason: z.string().optional() })),
  async (c) => {
    const id = c.req.param('id');
    await c.env.DB.prepare(
      "UPDATE listings SET status = 'rejected', updated_at = ? WHERE id = ?"
    ).bind(new Date().toISOString(), id).run();
    return c.json({ success: true, data: null });
  }
);

/** GET /admin/reports */
admin.get('/reports', async (c) => {
  const result = await c.env.DB.prepare(
    "SELECT r.*, u.name AS reporter_name FROM reports r JOIN users u ON u.id = r.reporter_id WHERE r.status = 'pending' ORDER BY r.created_at ASC LIMIT 50"
  ).all<Report & { reporter_name: string }>();
  return c.json({ success: true, data: result.results ?? [] });
});

/** PUT /admin/reports/:id/review */
admin.put(
  '/reports/:id/review',
  zValidator('json', z.object({ status: z.enum(['reviewed', 'dismissed']) })),
  async (c) => {
    const id = c.req.param('id');
    const { status } = c.req.valid('json');
    await c.env.DB.prepare('UPDATE reports SET status = ? WHERE id = ?')
      .bind(status, id)
      .run();
    return c.json({ success: true, data: null });
  }
);

/** GET /admin/users */
admin.get('/users', async (c) => {
  const result = await c.env.DB.prepare(
    'SELECT id, email, name, role, status, plan, is_verified, created_at FROM users ORDER BY created_at DESC LIMIT 100'
  ).all<Partial<User>>();
  return c.json({ success: true, data: result.results ?? [] });
});

/** PUT /admin/users/:id/suspend */
admin.put('/users/:id/suspend', async (c) => {
  const id = c.req.param('id');
  await c.env.DB.prepare(
    "UPDATE users SET status = 'suspended', updated_at = ? WHERE id = ?"
  ).bind(new Date().toISOString(), id).run();
  return c.json({ success: true, data: null });
});

/** PUT /admin/users/:id/ban */
admin.put('/users/:id/ban', async (c) => {
  const id = c.req.param('id');
  await c.env.DB.prepare(
    "UPDATE users SET status = 'banned', updated_at = ? WHERE id = ?"
  ).bind(new Date().toISOString(), id).run();
  return c.json({ success: true, data: null });
});

export default admin;
