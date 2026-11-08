import { Context, Next } from 'hono';
import type { Bindings } from '../types/index.js';

interface RateLimitOptions {
  /** Max requests per window */
  limit?: number;
  /** Window in seconds (default 60) */
  windowSec?: number;
  /** Route identifier used in KV key (defaults to c.req.path) */
  routeKey?: string;
}

/**
 * KV-backed rate limiter.
 * Key format: `rl:{ip}:{routeKey}`  — stored as a JSON counter with TTL.
 */
export function rateLimit(opts: RateLimitOptions = {}) {
  const limit = opts.limit ?? 60;
  const windowSec = opts.windowSec ?? 60;

  return async (
    c: Context<{ Bindings: Bindings }>,
    next: Next
  ): Promise<Response | void> => {
    const ip =
      c.req.header('CF-Connecting-IP') ??
      c.req.header('X-Forwarded-For') ??
      'unknown';
    const routeKey = opts.routeKey ?? c.req.path.replace(/\//g, '_');
    const kvKey = `rl:${ip}:${routeKey}`;

    const raw = await c.env.RATE_LIMIT.get(kvKey);
    const now = Math.floor(Date.now() / 1000);

    let count = 1;
    let windowStart = now;

    if (raw) {
      const parsed = JSON.parse(raw) as { count: number; windowStart: number };
      if (now - parsed.windowStart < windowSec) {
        count = parsed.count + 1;
        windowStart = parsed.windowStart;
      }
      // else: window expired — reset
    }

    const remaining = limit - count;
    const retryAfter = windowStart + windowSec - now;

    // Persist (upsert with TTL)
    await c.env.RATE_LIMIT.put(
      kvKey,
      JSON.stringify({ count, windowStart }),
      { expirationTtl: windowSec }
    );

    // Set standard headers
    c.header('X-RateLimit-Limit', String(limit));
    c.header('X-RateLimit-Remaining', String(Math.max(0, remaining)));
    c.header('X-RateLimit-Reset', String(windowStart + windowSec));

    if (count > limit) {
      c.header('Retry-After', String(retryAfter));
      return c.json(
        { success: false, error: 'Too many requests, please try again later.' },
        429
      );
    }

    await next();
  };
}

/** Stricter limiter for auth endpoints: 10 req / min */
export const authRateLimit = rateLimit({ limit: 10, windowSec: 60, routeKey: 'auth' });

/** Default limiter: 60 req / min */
export const defaultRateLimit = rateLimit({ limit: 60, windowSec: 60 });
