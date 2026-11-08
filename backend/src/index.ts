import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { defaultRateLimit } from './middleware/rateLimit.js';
import type { Bindings } from './types/index.js';

// Routes
import authRoutes from './routes/auth.js';
import listingsRoutes from './routes/listings.js';
import categoriesRoutes from './routes/categories.js';
import messagesRoutes from './routes/messages.js';
import requestsRoutes from './routes/requests.js';
import reviewsRoutes from './routes/reviews.js';
import usersRoutes from './routes/users.js';
import uploadsRoutes from './routes/uploads.js';
import adminRoutes from './routes/admin.js';

const app = new Hono<{ Bindings: Bindings }>();

// ---- Global Middleware ----

app.use(
  '*',
  cors({
    origin: (origin) => origin || '*',
    allowHeaders: ['Content-Type', 'Authorization'],
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    exposeHeaders: ['X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-RateLimit-Reset'],
    maxAge: 86400,
    credentials: true,
  })
);

app.use('*', logger());
app.use('*', defaultRateLimit);

// ---- Health check ----

app.get('/', (c) => {
  return c.json({
    success: true,
    data: {
      name: 'Marketplace API',
      version: '1.0.0',
      status: 'ok',
      timestamp: new Date().toISOString(),
    },
  });
});

app.get('/health', (c) =>
  c.json({ success: true, data: { status: 'healthy', timestamp: new Date().toISOString() } })
);

// ---- Mount Routes ----

app.route('/auth', authRoutes);
app.route('/listings', listingsRoutes);
app.route('/categories', categoriesRoutes);
app.route('/messages', messagesRoutes);
app.route('/requests', requestsRoutes);
app.route('/users', usersRoutes);
app.route('/uploads', uploadsRoutes);
app.route('/admin', adminRoutes);

// Reviews are nested under listings
app.route('/listings/:listingId/reviews', reviewsRoutes);

// ---- Serve Images from Cloudflare KV ----
app.get('/images/:id', async (c) => {
  const id = c.req.param('id');
  const result = await c.env.IMAGES_KV.getWithMetadata<{ contentType?: string }>(id, 'arrayBuffer');

  if (!result || !result.value) {
    return c.text('Imagen no encontrada', 404);
  }

  const contentType = result.metadata?.contentType || 'image/jpeg';
  return new Response(result.value, {
    headers: {
      'Content-Type': contentType,
      'Cache-Control': 'public, max-age=31536000, immutable',
      'Access-Control-Allow-Origin': '*',
    },
  });
});

// ---- Global Error Handler ----

app.onError((err, c) => {
  console.error('[Error]', err);
  const status = (err as { status?: number }).status ?? 500;
  return c.json(
    {
      success: false,
      error:
        c.env.ENVIRONMENT === 'development'
          ? err.message
          : 'An unexpected error occurred',
    },
    status as Parameters<typeof c.json>[1]
  );
});

app.notFound((c) =>
  c.json({ success: false, error: 'Route not found' }, 404)
);

export default app;
