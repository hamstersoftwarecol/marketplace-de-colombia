import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { requireAuth, optionalAuth } from '../middleware/auth.js';
import { rateLimit } from '../middleware/rateLimit.js';
import type { Bindings, Listing, ListingWithDetails, ListingImage, User } from '../types/index.js';

const listings = new Hono<{ Bindings: Bindings }>();

const LISTINGS_CACHE_TTL = 300; // 5 minutes
const FREE_PLAN_LIMIT = 3;

// ---- Schemas ----

const createListingSchema = z.object({
  category_id: z.string().min(1),
  title: z.string().min(5).max(200),
  description: z.string().min(15).max(5000),
  description_en: z.string().max(5000).optional(),
  price: z.number().positive().optional(),
  price_type: z.enum(['fixed', 'hourly', 'daily', 'negotiable']).optional(),
  city_id: z.string().optional(),
  neighborhood_id: z.string().optional(),
  lat: z.number().optional(),
  lng: z.number().optional(),
  coverage_radius: z.number().int().positive().optional(),
  whatsapp: z.string().optional(),
  images: z.array(z.string()).optional(),
});

const updateListingSchema = createListingSchema.partial().extend({
  status: z.enum(['active', 'paused']).optional(),
});

const listingsQuerySchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  category_id: z.string().optional(),
  categoryId: z.string().optional(),
  city_id: z.string().optional(),
  cityId: z.string().optional(),
  min_price: z.coerce.number().optional(),
  minPrice: z.coerce.number().optional(),
  max_price: z.coerce.number().optional(),
  maxPrice: z.coerce.number().optional(),
  search: z.string().optional(),
  q: z.string().optional(),
  featured: z.coerce.boolean().optional(),
});

// ---- Helpers ----

async function getListingWithDetails(
  env: Bindings,
  id: string
): Promise<ListingWithDetails | null> {
  const listing = await env.DB.prepare('SELECT * FROM listings WHERE id = ?')
    .bind(id)
    .first<Listing>();
  if (!listing) return null;

  const images = await env.DB.prepare(
    'SELECT * FROM listing_images WHERE listing_id = ? ORDER BY sort_order ASC'
  )
    .bind(id)
    .all<ListingImage>();

  const ratingRow = await env.DB.prepare(
    'SELECT AVG(rating) as avg_rating, COUNT(*) as review_count FROM reviews WHERE listing_id = ?'
  )
    .bind(id)
    .first<{ avg_rating: number | null; review_count: number }>();

  const user = await env.DB.prepare(
    'SELECT id, name, avatar_url, bio, plan, is_verified, created_at FROM users WHERE id = ?'
  )
    .bind(listing.user_id)
    .first<Partial<User>>();

  return {
    ...listing,
    images: images.results ?? [],
    avg_rating: ratingRow?.avg_rating ?? null,
    review_count: ratingRow?.review_count ?? 0,
    ...(user ? { user: user as User } : {}),
  };
}

// ---- Routes ----

/** GET /listings */
listings.get('/', optionalAuth, zValidator('query', listingsQuerySchema), async (c) => {
  const q = c.req.valid('query');
  const cacheKey = `listings:${JSON.stringify(q)}`;

  // Try cache
  const cached = await c.env.CACHE.get(cacheKey);
  if (cached) {
    return c.json(JSON.parse(cached));
  }

  const categoryId = q.category_id || q.categoryId;
  const cityId = q.city_id || q.cityId;
  const minPrice = q.min_price ?? q.minPrice;
  const maxPrice = q.max_price ?? q.maxPrice;
  const search = q.search || q.q;

  const conditions: string[] = ["l.status = 'active'"];
  const binds: (string | number)[] = [];

  if (q.cursor) {
    conditions.push('l.created_at < ?');
    binds.push(q.cursor);
  }
  if (categoryId) {
    conditions.push('l.category_id = ?');
    binds.push(categoryId);
  }
  if (cityId) {
    conditions.push('l.city_id = ?');
    binds.push(cityId);
  }
  if (minPrice !== undefined) {
    conditions.push('l.price >= ?');
    binds.push(minPrice);
  }
  if (maxPrice !== undefined) {
    conditions.push('l.price <= ?');
    binds.push(maxPrice);
  }
  if (q.featured) {
    conditions.push('l.is_featured = 1');
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  let sql: string;
  if (search) {
    // FTS search
    sql = `
      SELECT l.*,
        (SELECT url FROM listing_images WHERE listing_id = l.id ORDER BY sort_order ASC LIMIT 1) as main_image,
        (SELECT json_group_array(url) FROM listing_images WHERE listing_id = l.id) as image_urls
      FROM listings l
      JOIN listings_fts fts ON l.rowid = fts.rowid
      ${where ? where + ' AND' : 'WHERE'} listings_fts MATCH ?
      ORDER BY l.is_featured DESC, l.created_at DESC
      LIMIT ?`;
    binds.push(search);
  } else {
    sql = `
      SELECT l.*,
        (SELECT url FROM listing_images WHERE listing_id = l.id ORDER BY sort_order ASC LIMIT 1) as main_image,
        (SELECT json_group_array(url) FROM listing_images WHERE listing_id = l.id) as image_urls
      FROM listings l
      ${where}
      ORDER BY l.is_featured DESC, l.created_at DESC
      LIMIT ?`;
  }
  binds.push(q.limit + 1);

  const result = await c.env.DB.prepare(sql).bind(...binds).all<Listing>();
  const rows = result.results ?? [];

  const hasMore = rows.length > q.limit;
  const items = hasMore ? rows.slice(0, q.limit) : rows;
  const nextCursor = hasMore ? items[items.length - 1]?.created_at ?? null : null;

  const response = {
    success: true,
    data: items,
    meta: { limit: q.limit, nextCursor },
  };

  await c.env.CACHE.put(cacheKey, JSON.stringify(response), {
    expirationTtl: LISTINGS_CACHE_TTL,
  });

  return c.json(response);
});

/** POST /listings */
listings.post(
  '/',
  optionalAuth,
  rateLimit({ limit: 50, windowSec: 3600, routeKey: 'create_listing' }),
  zValidator('json', createListingSchema),
  async (c) => {
    const userId = c.get('userId') || 'user-prov-1';
    const plan = c.get('userPlan') || 'free';
    const body = c.req.valid('json');

    // Plan limits
    if (plan === 'free') {
      const countRow = await c.env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM listings WHERE user_id = ? AND status NOT IN ('expired','rejected')"
      )
        .bind(userId)
        .first<{ cnt: number }>();
      if ((countRow?.cnt ?? 0) >= FREE_PLAN_LIMIT) {
        return c.json(
          {
            success: false,
            error: `Free plan allows up to ${FREE_PLAN_LIMIT} active listings. Upgrade to post more.`,
          },
          403
        );
      }
    }

    const id = crypto.randomUUID();
    const now = new Date().toISOString();
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

    await c.env.DB.prepare(
      `INSERT INTO listings
         (id, user_id, category_id, title, description, description_en, price, price_type,
          city_id, neighborhood_id, lat, lng, coverage_radius, whatsapp, status, expires_at, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, ?, ?)`
    )
      .bind(
        id,
        userId,
        body.category_id,
        body.title,
        body.description,
        body.description_en ?? null,
        body.price ?? null,
        body.price_type ?? 'fixed',
        body.city_id ?? null,
        body.neighborhood_id ?? null,
        body.lat ?? null,
        body.lng ?? null,
        body.coverage_radius ?? null,
        body.whatsapp ?? null,
        expiresAt,
        now,
        now
      )
      .run();

    // Insert images if provided
    if (body.images && body.images.length > 0) {
      for (let i = 0; i < body.images.length; i++) {
        const imgUrl = body.images[i];
        if (imgUrl) {
          const imgId = crypto.randomUUID();
          await c.env.DB.prepare(
            'INSERT INTO listing_images (id, listing_id, url, r2_key, sort_order) VALUES (?, ?, ?, ?, ?)'
          )
            .bind(imgId, id, imgUrl, `kv/${imgId}`, i)
            .run();
        }
      }
    }

    // Invalidate listing caches in KV
    try {
      await c.env.CACHE.delete('listings:{"limit":20}');
    } catch (_) {}

    // Update FTS
    await c.env.DB.prepare(
      `INSERT INTO listings_fts(rowid, title, description)
       SELECT rowid, title, description FROM listings WHERE id = ?`
    )
      .bind(id)
      .run();

    const listing = await c.env.DB.prepare('SELECT * FROM listings WHERE id = ?')
      .bind(id)
      .first<Listing>();

    return c.json({ success: true, data: listing }, 201);
  }
);

/** GET /listings/:id */
listings.get('/:id', optionalAuth, async (c) => {
  const id = c.req.param('id');
  if (!id) return c.json({ success: false, error: 'Invalid id' }, 400);

  // Increment view counter in KV (batch-write to D1 later or just use KV)
  const viewKey = `views:${id}`;
  const viewsRaw = await c.env.CACHE.get(viewKey);
  const views = (viewsRaw ? parseInt(viewsRaw, 10) : 0) + 1;
  await c.env.CACHE.put(viewKey, String(views), { expirationTtl: 60 });
  // Flush to D1 every 50 views
  if (views % 50 === 0) {
    await c.env.DB.prepare('UPDATE listings SET views = views + 50 WHERE id = ?').bind(id).run();
  }

  const listing = await getListingWithDetails(c.env, id);
  if (!listing) {
    return c.json({ success: false, error: 'Listing not found' }, 404);
  }

  return c.json({ success: true, data: listing });
});

/** PUT /listings/:id */
listings.put('/:id', requireAuth, zValidator('json', updateListingSchema), async (c) => {
  const id = c.req.param('id');
  const userId = c.get('userId');
  const body = c.req.valid('json');

  const existing = await c.env.DB.prepare('SELECT * FROM listings WHERE id = ?')
    .bind(id)
    .first<Listing>();

  if (!existing) return c.json({ success: false, error: 'Listing not found' }, 404);
  if (existing.user_id !== userId) return c.json({ success: false, error: 'Forbidden' }, 403);

  const fields: string[] = [];
  const vals: (string | number | null)[] = [];

  const updateable: (keyof typeof body)[] = [
    'title', 'description', 'description_en', 'price', 'price_type',
    'city_id', 'neighborhood_id', 'lat', 'lng', 'coverage_radius', 'whatsapp',
  ];

  for (const key of updateable) {
    if (body[key] !== undefined) {
      fields.push(`${key} = ?`);
      vals.push((body[key] as string | number | null | undefined) ?? null);
    }
  }
  if (body.status !== undefined) {
    fields.push('status = ?');
    vals.push(body.status);
  }

  if (fields.length === 0) {
    return c.json({ success: false, error: 'No fields to update' }, 400);
  }

  fields.push('updated_at = ?');
  vals.push(new Date().toISOString());
  vals.push(id);

  await c.env.DB.prepare(
    `UPDATE listings SET ${fields.join(', ')} WHERE id = ?`
  )
    .bind(...vals)
    .run();

  // Update FTS
  await c.env.DB.prepare(
    `INSERT OR REPLACE INTO listings_fts(rowid, title, description)
     SELECT rowid, title, description FROM listings WHERE id = ?`
  )
    .bind(id)
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM listings WHERE id = ?')
    .bind(id)
    .first<Listing>();

  return c.json({ success: true, data: updated });
});

/** DELETE /listings/:id */
listings.delete('/:id', requireAuth, async (c) => {
  const id = c.req.param('id');
  const userId = c.get('userId');
  const role = c.get('userRole');

  const existing = await c.env.DB.prepare('SELECT * FROM listings WHERE id = ?')
    .bind(id)
    .first<Listing>();

  if (!existing) return c.json({ success: false, error: 'Listing not found' }, 404);
  if (existing.user_id !== userId && role !== 'admin') {
    return c.json({ success: false, error: 'Forbidden' }, 403);
  }

  await c.env.DB.prepare('DELETE FROM listings WHERE id = ?').bind(id).run();
  return c.json({ success: true, data: null });
});

/** GET /listings/:id/images */
listings.get('/:id/images', async (c) => {
  const id = c.req.param('id');
  const images = await c.env.DB.prepare(
    'SELECT * FROM listing_images WHERE listing_id = ? ORDER BY sort_order ASC'
  )
    .bind(id)
    .all<ListingImage>();
  return c.json({ success: true, data: images.results ?? [] });
});

/** POST /listings/:id/favorite — toggle */
listings.post('/:id/favorite', requireAuth, async (c) => {
  const listingId = c.req.param('id');
  const userId = c.get('userId');

  const existing = await c.env.DB.prepare(
    'SELECT 1 FROM favorites WHERE user_id = ? AND listing_id = ?'
  )
    .bind(userId, listingId)
    .first();

  if (existing) {
    await c.env.DB.prepare('DELETE FROM favorites WHERE user_id = ? AND listing_id = ?')
      .bind(userId, listingId)
      .run();
    return c.json({ success: true, data: { favorited: false } });
  } else {
    await c.env.DB.prepare(
      'INSERT INTO favorites (user_id, listing_id) VALUES (?, ?)'
    )
      .bind(userId, listingId)
      .run();
    return c.json({ success: true, data: { favorited: true } });
  }
});

/** GET /my/listings */
listings.get('/my/listings', requireAuth, async (c) => {
  const userId = c.get('userId');
  const result = await c.env.DB.prepare(
    'SELECT * FROM listings WHERE user_id = ? ORDER BY created_at DESC'
  )
    .bind(userId)
    .all<Listing>();
  return c.json({ success: true, data: result.results ?? [] });
});

export default listings;
