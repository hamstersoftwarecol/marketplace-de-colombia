import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import type { Bindings, Review } from '../types/index.js';

const reviews = new Hono<{ Bindings: Bindings }>();

const reviewSchema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(1000).optional(),
});

/** GET /listings/:listingId/reviews */
reviews.get('/', async (c) => {
  const listingId = c.req.param('listingId');

  const result = await c.env.DB.prepare(
    `SELECT r.*, u.name AS reviewer_name, u.avatar_url AS reviewer_avatar
     FROM reviews r
     JOIN users u ON u.id = r.reviewer_id
     WHERE r.listing_id = ?
     ORDER BY r.created_at DESC`
  )
    .bind(listingId)
    .all<Review & { reviewer_name: string; reviewer_avatar: string | null }>();

  const stats = await c.env.DB.prepare(
    'SELECT AVG(rating) AS avg_rating, COUNT(*) AS total FROM reviews WHERE listing_id = ?'
  )
    .bind(listingId)
    .first<{ avg_rating: number | null; total: number }>();

  return c.json({
    success: true,
    data: result.results ?? [],
    meta: { avg_rating: stats?.avg_rating ?? null, total: stats?.total ?? 0 },
  });
});

/** POST /listings/:listingId/reviews */
reviews.post('/', requireAuth, zValidator('json', reviewSchema), async (c) => {
  const listingId = c.req.param('listingId');
  const reviewerId = c.get('userId');
  const body = c.req.valid('json');

  // Check listing exists and is owned by someone else
  const listing = await c.env.DB.prepare('SELECT * FROM listings WHERE id = ?')
    .bind(listingId)
    .first<{ id: string; user_id: string }>();
  if (!listing) return c.json({ success: false, error: 'Listing not found' }, 404);
  if (listing.user_id === reviewerId) {
    return c.json({ success: false, error: 'Cannot review your own listing' }, 400);
  }

  // One review per user per listing
  const existing = await c.env.DB.prepare(
    'SELECT id FROM reviews WHERE listing_id = ? AND reviewer_id = ?'
  )
    .bind(listingId, reviewerId)
    .first();
  if (existing) {
    return c.json({ success: false, error: 'You have already reviewed this listing' }, 409);
  }

  const id = crypto.randomUUID();
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    'INSERT INTO reviews (id, listing_id, reviewer_id, rating, comment, created_at) VALUES (?, ?, ?, ?, ?, ?)'
  )
    .bind(id, listingId, reviewerId, body.rating, body.comment ?? null, now)
    .run();

  const review = await c.env.DB.prepare('SELECT * FROM reviews WHERE id = ?')
    .bind(id)
    .first<Review>();

  return c.json({ success: true, data: review }, 201);
});

export default reviews;
