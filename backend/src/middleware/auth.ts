import { Context, Next } from 'hono';
import { decode } from 'hono/jwt';
import type { Bindings, JWTPayload, KVSession } from '../types/index.js';

/** Verify a JWT using Web Crypto directly (avoids hono/jwt's broken verify signature) */
async function verifyJWT(token: string, secret: string): Promise<JWTPayload> {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('Invalid JWT');

  const enc = new TextEncoder();
  const keyData = enc.encode(secret);
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    keyData,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['verify']
  );

  const signingInput = `${parts[0]}.${parts[1]}`;
  const sigBytes = Uint8Array.from(
    atob(parts[2]!.replace(/-/g, '+').replace(/_/g, '/')),
    c => c.charCodeAt(0)
  );

  const valid = await crypto.subtle.verify(
    'HMAC',
    cryptoKey,
    sigBytes,
    enc.encode(signingInput)
  );

  if (!valid) throw new Error('Invalid JWT signature');

  const { payload } = decode(token);
  return payload as unknown as JWTPayload;
}

/** Extend Hono context variables */
declare module 'hono' {
  interface ContextVariableMap {
    userId: string;
    userEmail: string;
    userRole: 'user' | 'admin';
    userPlan: 'free' | 'basic' | 'pro';
    sessionToken: string;
    jwtPayload: JWTPayload;
  }
}

function extractToken(c: Context<{ Bindings: Bindings }>): string | null {
  const auth = c.req.header('Authorization');
  if (!auth?.startsWith('Bearer ')) return null;
  return auth.slice(7);
}

/** Require a valid JWT + active KV session. Returns 401 if missing or invalid. */
export async function requireAuth(
  c: Context<{ Bindings: Bindings }>,
  next: Next
): Promise<Response | void> {
  const token = extractToken(c);
  if (!token) {
    return c.json({ success: false, error: 'Authorization required' }, 401);
  }

  let payload: JWTPayload;
  try {
    payload = await verifyJWT(token, c.env.JWT_SECRET);
  } catch {
    return c.json({ success: false, error: 'Invalid or expired token' }, 401);
  }

  // Fast KV session check
  const kvKey = `session:${payload.sub}:${payload.sessionToken}`;
  const sessionRaw = await c.env.SESSIONS.get(kvKey);
  if (!sessionRaw) {
    return c.json({ success: false, error: 'Session expired or revoked' }, 401);
  }

  let session: KVSession;
  try {
    session = JSON.parse(sessionRaw) as KVSession;
  } catch {
    return c.json({ success: false, error: 'Invalid session data' }, 401);
  }

  if (Date.now() / 1000 > session.expiresAt) {
    await c.env.SESSIONS.delete(kvKey);
    return c.json({ success: false, error: 'Session expired' }, 401);
  }

  c.set('userId', payload.sub);
  c.set('userEmail', payload.email);
  c.set('userRole', payload.role);
  c.set('userPlan', payload.plan);
  c.set('sessionToken', payload.sessionToken);
  c.set('jwtPayload', payload);

  await next();
}

/** Optionally parse JWT — does not block unauthenticated requests. */
export async function optionalAuth(
  c: Context<{ Bindings: Bindings }>,
  next: Next
): Promise<Response | void> {
  const token = extractToken(c);
  if (token) {
    try {
      const payload = await verifyJWT(token, c.env.JWT_SECRET);
      const kvKey = `session:${payload.sub}:${payload.sessionToken}`;
      const sessionRaw = await c.env.SESSIONS.get(kvKey);
      if (sessionRaw) {
        const session = JSON.parse(sessionRaw) as KVSession;
        if (Date.now() / 1000 <= session.expiresAt) {
          c.set('userId', payload.sub);
          c.set('userEmail', payload.email);
          c.set('userRole', payload.role);
          c.set('userPlan', payload.plan);
          c.set('sessionToken', payload.sessionToken);
          c.set('jwtPayload', payload);
        }
      }
    } catch {
      // silently ignore invalid token for optional auth
    }
  }
  await next();
}

/** Require the user to have the 'admin' role. Must come after requireAuth. */
export async function requireAdmin(
  c: Context<{ Bindings: Bindings }>,
  next: Next
): Promise<Response | void> {
  const role = c.get('userRole');
  if (role !== 'admin') {
    return c.json({ success: false, error: 'Forbidden: admin access required' }, 403);
  }
  await next();
}
