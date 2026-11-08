import { Hono } from 'hono';
import { optionalAuth } from '../middleware/auth.js';
import type { Bindings } from '../types/index.js';

const uploads = new Hono<{ Bindings: Bindings }>();

interface ImageMetadata {
  contentType: string;
  size: number;
  uploadedAt: string;
  userId?: string;
}

/**
 * POST /uploads — Upload image directly to Cloudflare KV
 * Accepts multipart/form-data (field "file" or "image") or application/json { image: "data:image/jpeg;base64,...", contentType?: string }
 */
uploads.post('/', optionalAuth, async (c) => {
  const userId = c.get('userId');
  const contentTypeHeader = c.req.header('Content-Type') || '';

  let buffer: ArrayBuffer;
  let mimeType = 'image/jpeg';
  let ext = 'jpg';

  if (contentTypeHeader.includes('multipart/form-data')) {
    const formData = await c.req.formData();
    const file = (formData.get('file') || formData.get('image')) as File | null;

    if (!file) {
      return c.json({ success: false, error: 'No se envió ningún archivo de imagen' }, 400);
    }

    mimeType = file.type || 'image/jpeg';
    if (!mimeType.startsWith('image/')) {
      return c.json({ success: false, error: 'El archivo debe ser una imagen (JPG, PNG, WebP)' }, 400);
    }

    buffer = await file.arrayBuffer();
    if (file.name.includes('.')) {
      ext = file.name.split('.').pop()?.toLowerCase() || 'jpg';
    }
  } else if (contentTypeHeader.includes('application/json')) {
    const body = await c.req.json<{ image: string; contentType?: string }>();
    if (!body || !body.image) {
      return c.json({ success: false, error: 'Falta campo base64 de la imagen' }, 400);
    }

    let base64Data = body.image;
    if (base64Data.includes(';base64,')) {
      const parts = base64Data.split(';base64,');
      mimeType = parts[0]?.replace('data:', '') || 'image/jpeg';
      base64Data = parts[1] || '';
    } else if (body.contentType) {
      mimeType = body.contentType;
    }

    const binaryString = atob(base64Data);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    buffer = bytes.buffer;
  } else {
    // Raw binary upload
    buffer = await c.req.arrayBuffer();
    mimeType = contentTypeHeader || 'image/jpeg';
  }

  // 10 MB limit for KV
  if (buffer.byteLength > 10 * 1024 * 1024) {
    return c.json({ success: false, error: 'La imagen excede el límite de 10 MB' }, 400);
  }

  const imageId = `${crypto.randomUUID()}.${ext}`;
  const metadata: ImageMetadata = {
    contentType: mimeType,
    size: buffer.byteLength,
    uploadedAt: new Date().toISOString(),
    ...(userId ? { userId } : {}),
  };

  await c.env.IMAGES_KV.put(imageId, buffer, {
    metadata,
  });

  // Construct URL
  const host = c.req.header('host') || 'marketplace-api.business-alejandrolopezmurillo.workers.dev';
  const proto = host.includes('localhost') ? 'http' : 'https';
  const publicUrl = `${proto}://${host}/images/${imageId}`;

  return c.json({
    success: true,
    data: {
      id: imageId,
      url: publicUrl,
      size: buffer.byteLength,
      contentType: mimeType,
    },
  });
});

/**
 * DELETE /uploads/:id — Remove an image from KV
 */
uploads.delete('/:id', optionalAuth, async (c) => {
  const id = c.req.param('id');
  if (id) {
    await c.env.IMAGES_KV.delete(id);
  }
  return c.json({ success: true, message: 'Imagen eliminada de KV' });
});

export default uploads;
