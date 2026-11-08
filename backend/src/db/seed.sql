-- ============================================================
-- Marketplace Seed Data
-- ============================================================

-- Main Categories
INSERT OR IGNORE INTO categories (id, parent_id, name_es, name_en, icon, color, sort_order) VALUES
  ('servicios',    NULL, 'Servicios',     'Services',    '🔧', '#3B82F6', 1),
  ('vivienda',     NULL, 'Vivienda',      'Housing',     '🏠', '#10B981', 2),
  ('empleos',      NULL, 'Empleos',       'Jobs',        '💼', '#F59E0B', 3),
  ('vehiculos',    NULL, 'Vehículos',     'Vehicles',    '🚗', '#EF4444', 4),
  ('segunda-mano', NULL, 'Segunda Mano',  'Second Hand', '♻️', '#8B5CF6', 5);

-- Subcategories: Servicios
INSERT OR IGNORE INTO categories (id, parent_id, name_es, name_en, icon, color, sort_order) VALUES
  ('mudanzas',      'servicios', 'Mudanzas',    'Moving',      '📦', '#3B82F6', 1),
  ('limpieza',      'servicios', 'Limpieza',    'Cleaning',    '🧹', '#3B82F6', 2),
  ('plomeria',      'servicios', 'Plomería',    'Plumbing',    '🔩', '#3B82F6', 3),
  ('electricidad',  'servicios', 'Electricidad','Electrical',  '⚡', '#3B82F6', 4),
  ('pintura',       'servicios', 'Pintura',     'Painting',    '🎨', '#3B82F6', 5),
  ('jardineria',    'servicios', 'Jardinería',  'Gardening',   '🌱', '#3B82F6', 6);

-- Subcategories: Vivienda
INSERT OR IGNORE INTO categories (id, parent_id, name_es, name_en, icon, color, sort_order) VALUES
  ('arriendos',   'vivienda', 'Arriendos',   'Rentals',    '🔑', '#10B981', 1),
  ('venta',       'vivienda', 'Venta',       'For Sale',   '🏡', '#10B981', 2),
  ('habitaciones','vivienda', 'Habitaciones','Rooms',      '🛏️', '#10B981', 3);

-- Subcategories: Empleos
INSERT OR IGNORE INTO categories (id, parent_id, name_es, name_en, icon, color, sort_order) VALUES
  ('tiempo-completo', 'empleos', 'Tiempo Completo', 'Full Time',  '⏰', '#F59E0B', 1),
  ('tiempo-parcial',  'empleos', 'Tiempo Parcial',  'Part Time',  '🕐', '#F59E0B', 2),
  ('freelance',       'empleos', 'Freelance',        'Freelance',  '💻', '#F59E0B', 3);

-- Cities (Colombia)
INSERT OR IGNORE INTO cities (id, name, department, lat, lng) VALUES
  ('bogota',        'Bogotá',        'Cundinamarca', 4.7110,   -74.0721),
  ('medellin',      'Medellín',      'Antioquia',    6.2442,   -75.5812),
  ('cali',          'Cali',          'Valle del Cauca', 3.4516, -76.5320),
  ('cartagena',     'Cartagena',     'Bolívar',      10.3910,  -75.4794),
  ('barranquilla',  'Barranquilla',  'Atlántico',    10.9639,  -74.7964),
  ('bucaramanga',   'Bucaramanga',   'Santander',    7.1193,   -73.1227),
  ('manizales',     'Manizales',     'Caldas',       5.0703,   -75.5138),
  ('pereira',       'Pereira',       'Risaralda',    4.8143,   -75.6946);

-- Admin user (password: Admin1234! — PBKDF2 SHA-256 100k iters — replace hash in production)
-- This is a placeholder; actual hash is generated at runtime via the register endpoint
INSERT OR IGNORE INTO users (id, email, password_hash, name, role, status, is_verified) VALUES
  ('admin-user-001', 'admin@marketplace.local', 'CHANGE_ME_USE_REGISTER_ENDPOINT', 'Admin', 'admin', 'active', 1);
