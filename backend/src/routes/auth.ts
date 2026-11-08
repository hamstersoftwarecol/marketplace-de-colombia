import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { sign } from 'hono/jwt';
import { authRateLimit } from '../middleware/rateLimit.js';
import { requireAuth, optionalAuth } from '../middleware/auth.js';
import type { Bindings, User, PublicUser, KVSession, JWTPayload } from '../types/index.js';

const auth = new Hono<{ Bindings: Bindings }>();

// ---- Helpers ----

const JWT_EXP_SEC = 60 * 60 * 24 * 7; // 7 days
const SESSION_EXP_SEC = 60 * 60 * 24 * 30; // 30 days

async function hashPassword(password: string): Promise<string> {
  const enc = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    enc.encode(password),
    { name: 'PBKDF2' },
    false,
    ['deriveBits']
  );
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations: 100_000, hash: 'SHA-256' },
    keyMaterial,
    256
  );
  const hashArr = Array.from(new Uint8Array(bits));
  const saltArr = Array.from(salt);
  const hashHex = hashArr.map(b => b.toString(16).padStart(2, '0')).join('');
  const saltHex = saltArr.map(b => b.toString(16).padStart(2, '0')).join('');
  return `${saltHex}:${hashHex}`;
}

async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const [saltHex, hashHex] = stored.split(':');
  if (!saltHex || !hashHex) return false;
  const salt = new Uint8Array(saltHex.match(/.{2}/g)!.map(b => parseInt(b, 16)));
  const enc = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    enc.encode(password),
    { name: 'PBKDF2' },
    false,
    ['deriveBits']
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations: 100_000, hash: 'SHA-256' },
    keyMaterial,
    256
  );
  const derived = Array.from(new Uint8Array(bits))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  return derived === hashHex;
}

function toPublicUser(u: User): PublicUser {
  const { password_hash: _ph, oauth_id: _oi, ...pub } = u;
  void _ph; void _oi;
  return pub;
}

async function createSession(
  env: Bindings,
  user: User,
  deviceInfo?: string,
  ipAddress?: string
): Promise<{ jwt: string; sessionToken: string }> {
  const sessionToken = crypto.randomUUID();
  const now = Math.floor(Date.now() / 1000);
  const expiresAt = now + SESSION_EXP_SEC;

  const kvSession: KVSession = {
    userId: user.id,
    email: user.email,
    name: user.name,
    role: user.role,
    plan: user.plan,
    expiresAt,
  };

  const kvKey = `session:${user.id}:${sessionToken}`;
  await env.SESSIONS.put(kvKey, JSON.stringify(kvSession), {
    expirationTtl: SESSION_EXP_SEC,
  });

  // Also persist to D1
  const expiresAtStr = new Date(expiresAt * 1000).toISOString();
  await env.DB.prepare(
    `INSERT INTO sessions (token, user_id, device_info, ip_address, expires_at)
     VALUES (?, ?, ?, ?, ?)`
  )
    .bind(sessionToken, user.id, deviceInfo ?? null, ipAddress ?? null, expiresAtStr)
    .run();

  const payload: Omit<JWTPayload, 'iat'> = {
    sub: user.id,
    email: user.email,
    role: user.role,
    plan: user.plan,
    sessionToken,
    exp: now + JWT_EXP_SEC,
  };

  const jwt = await sign(payload, env.JWT_SECRET);
  return { jwt, sessionToken };
}

// ---- Schemas ----

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(2).max(100),
  phone: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

// ---- Routes ----

/** POST /auth/register */
auth.post('/register', authRateLimit, zValidator('json', registerSchema), async (c) => {
  const body = c.req.valid('json');

  const existing = await c.env.DB.prepare('SELECT id FROM users WHERE email = ?')
    .bind(body.email)
    .first<{ id: string }>();

  if (existing) {
    return c.json({ success: false, error: 'Email already registered' }, 409);
  }

  const id = crypto.randomUUID();
  const passwordHash = await hashPassword(body.password);
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `INSERT INTO users (id, email, password_hash, name, phone, role, status, plan, is_verified, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, 'user', 'active', 'free', 0, ?, ?)`
  )
    .bind(id, body.email, passwordHash, body.name, body.phone ?? null, now, now)
    .run();

  const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?')
    .bind(id)
    .first<User>();

  if (!user) {
    return c.json({ success: false, error: 'Failed to create user' }, 500);
  }

  const ip = c.req.header('CF-Connecting-IP') ?? undefined;
  const { jwt } = await createSession(c.env, user, undefined, ip);

  return c.json({ success: true, data: { token: jwt, user: toPublicUser(user) } }, 201);
});

/** POST /auth/login */
auth.post('/login', authRateLimit, zValidator('json', loginSchema), async (c) => {
  const body = c.req.valid('json');

  const user = await c.env.DB.prepare('SELECT * FROM users WHERE email = ?')
    .bind(body.email)
    .first<User>();

  if (!user || !user.password_hash) {
    return c.json({ success: false, error: 'Invalid credentials' }, 401);
  }

  if (user.status !== 'active') {
    return c.json({ success: false, error: `Account is ${user.status}` }, 403);
  }

  const valid = await verifyPassword(body.password, user.password_hash);
  if (!valid) {
    return c.json({ success: false, error: 'Invalid credentials' }, 401);
  }

  const ip = c.req.header('CF-Connecting-IP') ?? undefined;
  const deviceInfo = c.req.header('User-Agent') ?? undefined;
  const { jwt } = await createSession(c.env, user, deviceInfo, ip);

  return c.json({ success: true, data: { token: jwt, user: toPublicUser(user) } });
});

/** POST /auth/logout */
auth.post('/logout', requireAuth, async (c) => {
  const userId = c.get('userId');
  const sessionToken = c.get('sessionToken');

  const kvKey = `session:${userId}:${sessionToken}`;
  await c.env.SESSIONS.delete(kvKey);
  await c.env.DB.prepare('DELETE FROM sessions WHERE token = ?').bind(sessionToken).run();

  return c.json({ success: true, data: null });
});

/** GET /auth/me */
auth.get('/me', optionalAuth, async (c) => {
  const userId = c.get('userId');
  if (!userId) {
    return c.json({ success: true, data: null });
  }

  const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?')
    .bind(userId)
    .first<User>();

  if (!user) {
    return c.json({ success: true, data: null });
  }

  return c.json({ success: true, data: toPublicUser(user) });
});

/** POST /auth/refresh */
auth.post('/refresh', requireAuth, async (c) => {
  const userId = c.get('userId');
  const oldSessionToken = c.get('sessionToken');

  const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?')
    .bind(userId)
    .first<User>();

  if (!user) {
    return c.json({ success: false, error: 'User not found' }, 404);
  }

  // Delete old session
  const oldKvKey = `session:${userId}:${oldSessionToken}`;
  await c.env.SESSIONS.delete(oldKvKey);
  await c.env.DB.prepare('DELETE FROM sessions WHERE token = ?').bind(oldSessionToken).run();

  // Create new session
  const ip = c.req.header('CF-Connecting-IP') ?? undefined;
  const deviceInfo = c.req.header('User-Agent') ?? undefined;
  const { jwt } = await createSession(c.env, user, deviceInfo, ip);

  return c.json({ success: true, data: { token: jwt, user: toPublicUser(user) } });
});

export default auth;
