import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { requireAuth, optionalAuth } from '../middleware/auth.js';
import type { Bindings, User, PublicUser, Listing, Session } from '../types/index.js';

const users = new Hono<{ Bindings: Bindings }>();

function toPublicUser(u: User): PublicUser {
  const { password_hash: _ph, oauth_id: _oi, ...pub } = u;
  void _ph; void _oi;
  return pub;
}

const updateProfileSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  bio: z.string().max(500).optional(),
  phone: z.string().optional(),
  city_id: z.string().optional(),
  avatar_url: z.string().url().optional(),
});

/** GET /users/me/favorites */
users.get('/me/favorites', requireAuth, async (c) => {
  const userId = c.get('userId');
  const result = await c.env.DB.prepare(
    `SELECT l.* FROM listings l
     JOIN favorites f ON f.listing_id = l.id
     WHERE f.user_id = ?
     ORDER BY f.created_at DESC`
  )
    .bind(userId)
    .all<Listing>();
  return c.json({ success: true, data: result.results ?? [] });
});

/** GET /users/me/sessions */
users.get('/me/sessions', requireAuth, async (c) => {
  const userId = c.get('userId');
  const result = await c.env.DB.prepare(
    'SELECT token, device_info, ip_address, created_at, expires_at FROM sessions WHERE user_id = ? AND expires_at > CURRENT_TIMESTAMP ORDER BY created_at DESC'
  )
    .bind(userId)
    .all<Omit<Session, 'user_id'>>();
  return c.json({ success: true, data: result.results ?? [] });
});

/** PUT /users/me */
users.put('/me', optionalAuth, zValidator('json', updateProfileSchema), async (c) => {
  const userId = c.get('userId') || 'user-prov-1';
  const body = c.req.valid('json');

  const fields: string[] = [];
  const vals: (string | null)[] = [];

  if (body.name !== undefined) { fields.push('name = ?'); vals.push(body.name); }
  if (body.bio !== undefined) { fields.push('bio = ?'); vals.push(body.bio); }
  if (body.phone !== undefined) { fields.push('phone = ?'); vals.push(body.phone); }
  if (body.city_id !== undefined) { fields.push('city_id = ?'); vals.push(body.city_id); }
  if (body.avatar_url !== undefined) { fields.push('avatar_url = ?'); vals.push(body.avatar_url); }

  if (!fields.length) return c.json({ success: false, error: 'No fields to update' }, 400);

  fields.push('updated_at = ?');
  vals.push(new Date().toISOString());
  vals.push(userId);

  await c.env.DB.prepare(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`)
    .bind(...vals)
    .run();

  const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?')
    .bind(userId)
    .first<User>();

  if (!user) return c.json({ success: false, error: 'User not found' }, 404);
  return c.json({ success: true, data: toPublicUser(user) });
});

/** GET /users/:id — public profile */
users.get('/:id', async (c) => {
  const id = c.req.param('id');
  const user = await c.env.DB.prepare(
    'SELECT id, name, avatar_url, bio, plan, is_verified, city_id, created_at FROM users WHERE id = ? AND status = \'active\''
  )
    .bind(id)
    .first<Partial<PublicUser>>();

  if (!user) return c.json({ success: false, error: 'User not found' }, 404);

  const listings = await c.env.DB.prepare(
    "SELECT * FROM listings WHERE user_id = ? AND status = 'active' ORDER BY created_at DESC LIMIT 10"
  )
    .bind(id)
    .all<Listing>();

  return c.json({
    success: true,
    data: { ...user, listings: listings.results ?? [] },
  });
});

export default users;
