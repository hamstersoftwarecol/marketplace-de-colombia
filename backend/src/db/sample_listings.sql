-- Seed additional users (service providers)
INSERT OR IGNORE INTO users (id, email, password_hash, name, avatar_url, bio, phone, role, status, plan, is_verified, city_id)
VALUES
('user-prov-1', 'mudanzas.bogota@ejemplo.com', 'dummy_hash', 'Mudanzas & Acarreos El Cóndor', 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150', 'Más de 10 años de experiencia en mudanzas residenciales y empresariales en Bogotá y Cundinamarca.', '573105551234', 'user', 'active', 'pro', 1, 'bogota'),
('user-prov-2', 'fletes.medellin@ejemplo.com', 'dummy_hash', 'Transportes Medellín Express', 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150', 'Furgones modernos con mantas de protección, plataformas elevadoras y personal calificado.', '573147779876', 'user', 'active', 'pro', 1, 'medellin'),
('user-prov-3', 'plomeria.cali@ejemplo.com', 'dummy_hash', 'Plomería & Mantenimiento Valle', 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=150', 'Servicio técnico garantizado 24 horas. Destapes sin romper, detección de fugas y grifería.', '573189994321', 'user', 'active', 'basic', 1, 'cali'),
('user-prov-4', 'electricidad.bogota@ejemplo.com', 'dummy_hash', 'Ingeniería Eléctrica y Redes', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', 'Instalaciones eléctricas certificadas RETIE, iluminación LED, tableros y cableado estructurado.', '573001112233', 'user', 'active', 'basic', 1, 'bogota');

-- Listings
INSERT OR REPLACE INTO listings (id, user_id, category_id, title, description, description_en, price, price_type, city_id, lat, lng, coverage_radius, whatsapp, status, is_featured, views, expires_at)
VALUES
(
  'list-001',
  'user-prov-1',
  'servicios',
  'Mudanzas Residenciales y Acarreos en Furgón Cerrado Bogotá',
  'Ofrecemos servicio completo de mudanza en Bogotá y hacia otras ciudades. Incluye mantas de protección de algodón, lazos de amarre, carretas de carga y 2 operarios profesionales. Furgón NHR amplio y limpio. Emitimos factura y garantía de cuidado de muebles.',
  'Full moving and hauling service in Bogotá. Includes protective blankets, secure tie-downs, hand trucks, and 2 professional movers.',
  180000,
  'fixed',
  'bogota',
  4.6850,
  -74.0500,
  30,
  '573105551234',
  'active',
  1,
  145,
  datetime('now', '+60 days')
),
(
  'list-002',
  'user-prov-2',
  'servicios',
  'Acarreos Rápidos y Pequeños Fletes Medellín - Valle de Aburrá',
  'Transporte de sofás, neveras, lavadoras, escritorios y cajas. Camioneta pickup y furgón mediano disponibles los 7 días de la semana. Cobertura en Poblado, Laureles, Envigado, Bello e Itagüí. Cotización inmediata por WhatsApp con fotos de tus objetos.',
  'Fast hauling and small moves in Medellín, Envigado, and surrounding areas. Vans and pickups available 7 days a week.',
  85000,
  'hourly',
  'medellin',
  6.2100,
  -75.5700,
  25,
  '573147779876',
  'active',
  1,
  210,
  datetime('now', '+60 days')
),
(
  'list-003',
  'user-prov-3',
  'servicios',
  'Plomero 24 Horas en Cali - Detección de Fugas y Destapes',
  'Atención de emergencias 24/7 en Cali. Destape de cañerías con sonda eléctrica sin romper baldosas. Reparación de tubos rotos, filtros, motobombas y cambio de griferías. Experiencia comprobada y repuestos originales.',
  '24/7 Emergency Plumbing Services in Cali. Leak detection, pipe unclogging, and pump repairs with warranty.',
  65000,
  'fixed',
  'cali',
  3.4400,
  -76.5300,
  20,
  '573189994321',
  'active',
  0,
  98,
  datetime('now', '+60 days')
),
(
  'list-004',
  'user-prov-4',
  'servicios',
  'Electricista Certificado - Arreglos de Tableros y Cortocircuitos',
  'Servicio técnico electricista a domicilio. Reparación de cortocircuitos, instalación de lámparas LED, ventiladores de techo, tomas de corriente y puntos 220V para estufas y calentadores. Diagnóstico rápido y seguro.',
  'Certified electrician in Bogotá. Circuit breaker repairs, LED installations, 220V outlets, and general maintenance.',
  50000,
  'hourly',
  'bogota',
  4.7100,
  -74.0700,
  25,
  '573001112233',
  'active',
  0,
  82,
  datetime('now', '+60 days')
),
(
  'list-005',
  'user-prov-1',
  'servicios',
  'Mudanzas Nacionales Bogotá a Medellín, Cali y Costa Caribe',
  'Viajes directos y compartidos a nivel nacional. Camiones NPR de 5 toneladas y turbos aseguradas. Servicio de embalaje profesional en cartón corrugado y plástico burbuja para televisores y electrodomésticos delicados.',
  'Intercity moving services across Colombia: Bogotá, Medellín, Cali, and the Caribbean Coast.',
  850000,
  'negotiable',
  'bogota',
  4.6900,
  -74.0400,
  500,
  '573105551234',
  'active',
  1,
  315,
  datetime('now', '+60 days')
),
(
  'list-006',
  'user-prov-2',
  'servicios',
  'Pintura de Casas, Apartamentos y Fachadas en Medellín',
  'Pintores profesionales con acabados de primera. Lijado, resane de grietas, estuco y aplicación de pintura vinilo tipo 1 lavable. Dejamos todo limpio y protegido. Cotización sin costo en el área metropolitana.',
  'Professional interior and exterior painting services for homes and apartments in Medellín.',
  350000,
  'fixed',
  'medellin',
  6.2400,
  -75.5900,
  30,
  '573147779876',
  'active',
  0,
  74,
  datetime('now', '+60 days')
);

-- Listing Images
INSERT OR REPLACE INTO listing_images (id, listing_id, url, r2_key, sort_order)
VALUES
('img-001-1', 'list-001', 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800', 'seed/img-001-1.jpg', 0),
('img-001-2', 'list-001', 'https://images.unsplash.com/photo-1584905066893-7d5c142ba4e1?w=800', 'seed/img-001-2.jpg', 1),
('img-002-1', 'list-002', 'https://images.unsplash.com/photo-1519003722824-194d4455a60c?w=800', 'seed/img-002-1.jpg', 0),
('img-002-2', 'list-002', 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800', 'seed/img-002-2.jpg', 1),
('img-003-1', 'list-003', 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=800', 'seed/img-003-1.jpg', 0),
('img-004-1', 'list-004', 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800', 'seed/img-004-1.jpg', 0),
('img-005-1', 'list-005', 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800', 'seed/img-005-1.jpg', 0),
('img-006-1', 'list-006', 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=800', 'seed/img-006-1.jpg', 0);

-- Sync with FTS
INSERT INTO listings_fts(rowid, title, description)
SELECT rowid, title, description FROM listings WHERE id IN ('list-001','list-002','list-003','list-004','list-005','list-006');
