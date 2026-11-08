// ============================================================
// TypeScript Types & Interfaces
// ============================================================

/** Cloudflare Workers bindings */
export interface Bindings {
  DB: D1Database;
  SESSIONS: KVNamespace;
  RATE_LIMIT: KVNamespace;
  CACHE: KVNamespace;
  IMAGES_KV: KVNamespace;
  BUCKET?: R2Bucket;
  JWT_SECRET: string;
  ENVIRONMENT: string;
}

// ---- Entity Types ----

export interface User {
  id: string;
  email: string;
  password_hash?: string | null;
  oauth_provider?: string | null;
  oauth_id?: string | null;
  name: string;
  avatar_url?: string | null;
  bio?: string | null;
  phone?: string | null;
  role: 'user' | 'admin';
  status: 'active' | 'suspended' | 'banned';
  plan: 'free' | 'basic' | 'pro';
  plan_expires_at?: string | null;
  is_verified: number;
  city_id?: string | null;
  created_at: string;
  updated_at: string;
}

export type PublicUser = Omit<User, 'password_hash' | 'oauth_id'>;

export interface Category {
  id: string;
  parent_id?: string | null;
  name_es: string;
  name_en: string;
  icon?: string | null;
  color?: string | null;
  sort_order: number;
  is_active: number;
  subcategories?: Category[];
}

export interface City {
  id: string;
  name: string;
  department: string;
  lat?: number | null;
  lng?: number | null;
  is_active: number;
}

export interface Neighborhood {
  id: string;
  city_id: string;
  name: string;
}

export interface Listing {
  id: string;
  user_id: string;
  category_id: string;
  title: string;
  description: string;
  description_en?: string | null;
  price?: number | null;
  price_type: 'fixed' | 'hourly' | 'daily' | 'negotiable';
  city_id?: string | null;
  neighborhood_id?: string | null;
  lat?: number | null;
  lng?: number | null;
  coverage_radius?: number | null;
  whatsapp?: string | null;
  status: 'pending' | 'active' | 'paused' | 'expired' | 'rejected';
  is_featured: number;
  featured_until?: string | null;
  views: number;
  expires_at?: string | null;
  created_at: string;
  updated_at: string;
}

export interface ListingImage {
  id: string;
  listing_id: string;
  url: string;
  r2_key: string;
  sort_order: number;
  created_at: string;
}

export interface ListingWithDetails extends Listing {
  images: ListingImage[];
  avg_rating?: number | null;
  review_count?: number;
  user?: PublicUser | undefined;
  category?: Category | undefined;
  city?: City | undefined;
}

export interface Message {
  id: string;
  listing_id?: string | null;
  sender_id: string;
  receiver_id: string;
  content: string;
  image_url?: string | null;
  is_read: number;
  sent_at: string;
}

export interface Conversation {
  other_user_id: string;
  other_user_name: string;
  other_user_avatar?: string | null;
  listing_id?: string | null;
  listing_title?: string | null;
  last_message: string;
  last_message_at: string;
  unread_count: number;
}

export interface HelpRequest {
  id: string;
  user_id: string;
  category_id?: string | null;
  title: string;
  description: string;
  budget?: number | null;
  city_id?: string | null;
  neighborhood?: string | null;
  lat?: number | null;
  lng?: number | null;
  status: 'open' | 'in_progress' | 'resolved' | 'expired';
  expires_at?: string | null;
  created_at: string;
}

export interface Proposal {
  id: string;
  request_id: string;
  user_id: string;
  message: string;
  price?: number | null;
  created_at: string;
}

export interface Review {
  id: string;
  listing_id: string;
  reviewer_id: string;
  rating: number;
  comment?: string | null;
  created_at: string;
}

export interface Report {
  id: string;
  reporter_id: string;
  listing_id?: string | null;
  message_id?: string | null;
  reason: 'spam' | 'fraud' | 'inappropriate' | 'other';
  description?: string | null;
  status: 'pending' | 'reviewed' | 'dismissed';
  created_at: string;
}

export interface Payment {
  id: string;
  user_id: string;
  amount: number;
  currency: string;
  plan: string;
  gateway: string;
  gateway_id?: string | null;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  created_at: string;
}

export interface Session {
  token: string;
  user_id: string;
  device_info?: string | null;
  ip_address?: string | null;
  created_at: string;
  expires_at: string;
}

// ---- KV Session payload ----
export interface KVSession {
  userId: string;
  email: string;
  name: string;
  role: 'user' | 'admin';
  plan: 'free' | 'basic' | 'pro';
  expiresAt: number; // Unix timestamp (seconds)
}

// ---- JWT Payload ----
export interface JWTPayload {
  sub: string;      // user id
  email: string;
  role: 'user' | 'admin';
  plan: 'free' | 'basic' | 'pro';
  sessionToken: string;
  exp: number;
  iat: number;
}

// ---- API Request Types ----

export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
  phone?: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface CreateListingRequest {
  category_id: string;
  title: string;
  description: string;
  description_en?: string;
  price?: number;
  price_type?: 'fixed' | 'hourly' | 'daily' | 'negotiable';
  city_id?: string;
  neighborhood_id?: string;
  lat?: number;
  lng?: number;
  coverage_radius?: number;
  whatsapp?: string;
}

export interface UpdateListingRequest extends Partial<CreateListingRequest> {
  status?: 'active' | 'paused';
}

export interface CreateMessageRequest {
  receiver_id: string;
  listing_id?: string;
  content: string;
  image_url?: string;
}

export interface CreateHelpRequestRequest {
  category_id?: string;
  title: string;
  description: string;
  budget?: number;
  city_id?: string;
  neighborhood?: string;
  lat?: number;
  lng?: number;
}

export interface CreateProposalRequest {
  message: string;
  price?: number;
}

export interface CreateReviewRequest {
  rating: number;
  comment?: string;
}

export interface UpdateProfileRequest {
  name?: string;
  bio?: string;
  phone?: string;
  city_id?: string;
  avatar_url?: string;
}

export interface CreateReportRequest {
  listing_id?: string;
  message_id?: string;
  reason: 'spam' | 'fraud' | 'inappropriate' | 'other';
  description?: string;
}

// ---- API Response Types ----

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  meta?: {
    page?: number;
    limit?: number;
    total?: number;
    cursor?: string | null;
    nextCursor?: string | null;
  };
}

export interface AuthResponse {
  token: string;
  user: PublicUser;
}

// ---- Pagination ----
export interface CursorPaginationParams {
  cursor?: string;
  limit?: number;
}

export interface ListingsFilters extends CursorPaginationParams {
  category_id?: string;
  city_id?: string;
  min_price?: number;
  max_price?: number;
  search?: string;
  status?: string;
  featured?: boolean;
}
