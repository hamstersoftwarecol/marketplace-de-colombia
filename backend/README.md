# Marketplace API

A Hono + Cloudflare Workers backend for the Marketplace application.

## Stack

| Layer | Technology |
|-------|-----------|
| Framework | [Hono](https://hono.dev) v4+ |
| Runtime | Cloudflare Workers |
| Database | Cloudflare D1 (SQLite) |
| Cache / Sessions | Cloudflare KV |
| File Storage | Cloudflare KV (`IMAGES_KV`) |
| Validation | Zod |
| Auth | JWT via `hono/jwt` + KV sessions |
| Language | TypeScript (strict) |

---

## Prerequisites

- Node.js 20+
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/) v3+: `npm install -g wrangler`
- A Cloudflare account: `wrangler login`

---

## Setup

### 1. Install dependencies

```bash
cd backend
npm install
```

### 2. Create Cloudflare resources

#### D1 Database

```bash
wrangler d1 create marketplace-db
```

Copy the `database_id` from the output and update `wrangler.toml`:

```toml
[[d1_databases]]
binding = "DB"
database_name = "marketplace-db"
database_id = "<your-database-id>"
```

#### KV Namespaces

```bash
wrangler kv namespace create SESSIONS
wrangler kv namespace create RATE_LIMIT
wrangler kv namespace create CACHE
```

Update `wrangler.toml` with the IDs from each command output:

```toml
[[kv_namespaces]]
binding = "SESSIONS"
id = "<sessions-id>"

[[kv_namespaces]]
binding = "RATE_LIMIT"
id = "<rate-limit-id>"

[[kv_namespaces]]
binding = "CACHE"
id = "<cache-id>"
```

#### R2 Bucket

```bash
wrangler r2 bucket create marketplace-assets
```

### 3. Apply database schema

**Local development:**

```bash
npm run db:migrate:local
npm run db:seed:local
```

**Production:**

```bash
npm run db:migrate
npm run db:seed
```

---

## Development

```bash
npm run dev
```

The API will be available at `http://localhost:8787`.

---

## Deployment

```bash
npm run deploy
```

---

## Environment Variables

Set secrets via Wrangler (not in `wrangler.toml`):

```bash
wrangler secret put JWT_SECRET
```

| Variable | Description |
|----------|-------------|
| `JWT_SECRET` | Secret key for signing JWTs (use a strong random string) |
| `ENVIRONMENT` | `development` or `production` |

---

## API Overview

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/register` | — | Register a new user |
| POST | `/auth/login` | — | Login and receive JWT |
| POST | `/auth/logout` | ✅ | Invalidate session |
| GET | `/auth/me` | ✅ | Get current user |
| POST | `/auth/refresh` | ✅ | Refresh JWT |
| GET | `/listings` | — | List/search listings |
| POST | `/listings` | ✅ | Create listing |
| GET | `/listings/:id` | — | Get listing detail |
| PUT | `/listings/:id` | ✅ | Update listing |
| DELETE | `/listings/:id` | ✅ | Delete listing |
| POST | `/listings/:id/favorite` | ✅ | Toggle favorite |
| GET | `/listings/:listingId/reviews` | — | Listing reviews |
| POST | `/listings/:listingId/reviews` | ✅ | Post review |
| GET | `/categories` | — | Category tree |
| GET | `/messages` | ✅ | Inbox |
| POST | `/messages` | ✅ | Send message |
| PUT | `/messages/:id/read` | ✅ | Mark read |
| GET | `/requests` | — | Help requests |
| POST | `/requests` | ✅ | Create request |
| POST | `/requests/:id/proposals` | ✅ | Submit proposal |
| GET | `/users/:id` | — | Public profile |
| PUT | `/users/me` | ✅ | Update profile |
| POST | `/uploads/presign` | ✅ | Get upload URL |
| GET | `/admin/stats` | 🔑 Admin | Dashboard stats |
| GET | `/admin/listings/pending` | 🔑 Admin | Pending moderation |
| PUT | `/admin/listings/:id/approve` | 🔑 Admin | Approve listing |
| PUT | `/admin/listings/:id/reject` | 🔑 Admin | Reject listing |
| GET | `/admin/reports` | 🔑 Admin | Pending reports |
| GET | `/admin/users` | 🔑 Admin | All users |
| PUT | `/admin/users/:id/suspend` | 🔑 Admin | Suspend user |
| PUT | `/admin/users/:id/ban` | 🔑 Admin | Ban user |

---

## Response Format

All responses follow this shape:

```json
{
  "success": true,
  "data": { ... },
  "meta": { "nextCursor": "...", "limit": 20 }
}
```

Errors:

```json
{
  "success": false,
  "error": "Human-readable error message"
}
```

---

## Rate Limiting

- **Auth endpoints**: 10 requests / minute per IP
- **All other endpoints**: 60 requests / minute per IP

Exceeded limits return HTTP `429` with a `Retry-After` header.

---

## Plan Limits

| Plan | Max Active Listings |
|------|-------------------|
| free | 3 |
| basic | Unlimited |
| pro | Unlimited + featured |

---

## Notes

- Passwords are hashed with **PBKDF2-SHA256** (100,000 iterations) using the Web Crypto API
- Sessions are stored in **both** D1 (for audit) and **KV** (for fast validation)
- Listing search uses **SQLite FTS5** for full-text search
- Listing views are batched via KV counters (flushed every 50 views to D1)
- Category tree is cached in KV for 1 hour
- Listing list results are cached in KV for 5 minutes
