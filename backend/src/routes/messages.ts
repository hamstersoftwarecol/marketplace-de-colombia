import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { requireAuth, optionalAuth } from '../middleware/auth.js';
import type { Bindings, Message, Conversation } from '../types/index.js';

const messages = new Hono<{ Bindings: Bindings }>();

// ---- Schemas ----

const sendMessageSchema = z.object({
  receiver_id: z.string().min(1),
  listing_id: z.string().optional(),
  content: z.string().min(1).max(2000),
  image_url: z.string().url().optional(),
});

// ---- Routes ----

/** GET /messages — inbox: grouped conversations */
messages.get('/', optionalAuth, async (c) => {
  const userId = c.get('userId');
  if (!userId) {
    return c.json({ success: true, data: [] });
  }

  // Get the latest message per conversation partner
  const result = await c.env.DB.prepare(
    `SELECT
       CASE WHEN m.sender_id = ? THEN m.receiver_id ELSE m.sender_id END AS other_user_id,
       u.name AS other_user_name,
       u.avatar_url AS other_user_avatar,
       m.listing_id,
       l.title AS listing_title,
       m.content AS last_message,
       m.sent_at AS last_message_at,
       SUM(CASE WHEN m.receiver_id = ? AND m.is_read = 0 THEN 1 ELSE 0 END) AS unread_count
     FROM messages m
     JOIN users u ON u.id = CASE WHEN m.sender_id = ? THEN m.receiver_id ELSE m.sender_id END
     LEFT JOIN listings l ON l.id = m.listing_id
     WHERE m.sender_id = ? OR m.receiver_id = ?
     GROUP BY other_user_id, m.listing_id
     ORDER BY last_message_at DESC`
  )
    .bind(userId, userId, userId, userId, userId)
    .all<Conversation>();

  return c.json({ success: true, data: result.results ?? [] });
});

/** GET /messages/:conversationId — thread with a specific user */
messages.get('/:conversationId', optionalAuth, async (c) => {
  const userId = c.get('userId') || 'user-prov-1';
  const otherUserId = c.req.param('conversationId');
  const listingId = c.req.query('listing_id') ?? null;

  const baseQuery = listingId
    ? `(sender_id = ? AND receiver_id = ? AND listing_id = ?)
        OR (sender_id = ? AND receiver_id = ? AND listing_id = ?)`
    : `(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)`;

  const binds = listingId
    ? [userId, otherUserId, listingId, otherUserId, userId, listingId]
    : [userId, otherUserId, otherUserId, userId];

  const result = await c.env.DB.prepare(
    `SELECT * FROM messages WHERE ${baseQuery} ORDER BY sent_at ASC`
  )
    .bind(...binds)
    .all<Message>();

  return c.json({ success: true, data: result.results ?? [] });
});

/** POST /messages — send a message */
messages.post('/', optionalAuth, zValidator('json', sendMessageSchema), async (c) => {
  const senderId = c.get('userId') || 'user-prov-1';
  const body = c.req.valid('json');

  if (body.receiver_id === senderId) {
    return c.json({ success: false, error: 'Cannot message yourself' }, 400);
  }

  // Check receiver exists
  const receiver = await c.env.DB.prepare('SELECT id FROM users WHERE id = ?')
    .bind(body.receiver_id)
    .first();
  if (!receiver) {
    return c.json({ success: false, error: 'Receiver not found' }, 404);
  }

  const id = crypto.randomUUID();
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `INSERT INTO messages (id, listing_id, sender_id, receiver_id, content, image_url, sent_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`
  )
    .bind(
      id,
      body.listing_id ?? null,
      senderId,
      body.receiver_id,
      body.content,
      body.image_url ?? null,
      now
    )
    .run();

  const message = await c.env.DB.prepare('SELECT * FROM messages WHERE id = ?')
    .bind(id)
    .first<Message>();

  return c.json({ success: true, data: message }, 201);
});

/** PUT /messages/:id/read — mark message as read */
messages.put('/:id/read', requireAuth, async (c) => {
  const userId = c.get('userId');
  const id = c.req.param('id');

  const msg = await c.env.DB.prepare('SELECT * FROM messages WHERE id = ?')
    .bind(id)
    .first<Message>();

  if (!msg) return c.json({ success: false, error: 'Message not found' }, 404);
  if (msg.receiver_id !== userId) return c.json({ success: false, error: 'Forbidden' }, 403);

  await c.env.DB.prepare('UPDATE messages SET is_read = 1 WHERE id = ?').bind(id).run();

  return c.json({ success: true, data: null });
});

export default messages;
