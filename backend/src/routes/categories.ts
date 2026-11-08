import { Hono } from 'hono';
import type { Bindings, Category } from '../types/index.js';

const categories = new Hono<{ Bindings: Bindings }>();

const CACHE_TTL = 3600; // 1 hour

/** GET /categories — full tree */
categories.get('/', async (c) => {
  const cacheKey = 'categories:tree';
  const cached = await c.env.CACHE.get(cacheKey);
  if (cached) {
    return c.json(JSON.parse(cached));
  }

  const result = await c.env.DB.prepare(
    'SELECT * FROM categories WHERE is_active = 1 ORDER BY sort_order ASC'
  ).all<Category>();

  const rows = result.results ?? [];

  // Build tree
  const roots = rows.filter(r => !r.parent_id);
  for (const root of roots) {
    root.subcategories = rows.filter(r => r.parent_id === root.id);
  }

  const response = { success: true, data: roots };
  await c.env.CACHE.put(cacheKey, JSON.stringify(response), {
    expirationTtl: CACHE_TTL,
  });

  return c.json(response);
});

/** GET /categories/:id/subcategories */
categories.get('/:id/subcategories', async (c) => {
  const id = c.req.param('id');
  const result = await c.env.DB.prepare(
    'SELECT * FROM categories WHERE parent_id = ? AND is_active = 1 ORDER BY sort_order ASC'
  )
    .bind(id)
    .all<Category>();

  return c.json({ success: true, data: result.results ?? [] });
});

export default categories;
