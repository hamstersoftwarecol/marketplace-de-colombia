import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/listing_service.dart';
import '../providers/listings_provider.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _descEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _whatsappController = TextEditingController();

  String? _selectedCategoryId;
  String _priceType = 'fixed';
  String _selectedCity = 'bogota';
  bool _isLoading = false;
  bool _isUploadingImage = false;
  final List<String> _uploadedImageUrls = [];

  final List<Map<String, String>> _cities = [
    {'id': 'bogota', 'name': 'Bogotá, D.C.'},
    {'id': 'medellin', 'name': 'Medellín, Antioquia'},
    {'id': 'cali', 'name': 'Cali, Valle del Cauca'},
    {'id': 'barranquilla', 'name': 'Barranquilla, Atlántico'},
    {'id': 'cartagena', 'name': 'Cartagena, Bolívar'},
    {'id': 'bucaramanga', 'name': 'Bucaramanga, Santander'},
    {'id': 'manizales', 'name': 'Manizales, Caldas'},
    {'id': 'pereira', 'name': 'Pereira, Risaralda'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _descEnController.dispose();
    _priceController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(limit: 5);

      if (pickedFiles.isEmpty) return;

      setState(() => _isUploadingImage = true);

      final listingService = ref.read(listingServiceProvider);

      for (final file in pickedFiles) {
        final bytes = await file.readAsBytes();
        final mimeType = file.name.endsWith('.png')
            ? 'image/png'
            : file.name.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';

        final url = await listingService.uploadImage(bytes, mimeType: mimeType);
        if (mounted) {
          setState(() {
            _uploadedImageUrls.add(url);
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('${pickedFiles.length} foto(s) guardadas en Cloudflare KV'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error al subir imagen a KV: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final listingService = ref.read(listingServiceProvider);
      final price = double.tryParse(_priceController.text.trim());

      await listingService.createListing({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        if (_descEnController.text.trim().isNotEmpty)
          'description_en': _descEnController.text.trim(),
        'category_id': _selectedCategoryId,
        if (price != null) 'price': price,
        'price_type': _priceType,
        'city_id': _selectedCity,
        if (_whatsappController.text.trim().isNotEmpty)
          'whatsapp': _whatsappController.text.trim(),
        if (_uploadedImageUrls.isNotEmpty)
          'images': _uploadedImageUrls,
      });

      ref.invalidate(listingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('¡Anuncio publicado con éxito!'),
          ),
        );
        context.go('/listings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error al publicar anuncio: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Anuncio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Detalles del Anuncio', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text('Completa los campos para publicar tu servicio o producto',
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 24),

                  // Category Selector
                  Text('Categoría *', style: AppTextStyles.subtitle2),
                  const SizedBox(height: 8),
                  categoriesAsync.when(
                    data: (categories) => DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      hint: const Text('Selecciona una categoría'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(c.materialIcon, size: 20, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Text(c.nameEs),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error al cargar categorías'),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text('Título *', style: AppTextStyles.subtitle2),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Mudanzas y acarreos en furgón cerrado Bogotá',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 5) {
                        return 'El título debe tener al menos 5 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Description (Spanish)
                  Text('Descripción en Español *', style: AppTextStyles.subtitle2),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe lo que ofreces, cobertura, disponibilidad, qué incluye...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 15) {
                        return 'La descripción debe tener al menos 15 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Photos Section (Stored in Cloudflare KV)
                  Text('Fotos del Servicio / Producto (Cloudflare KV)', style: AppTextStyles.subtitle2),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              icon: _isUploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_photo_alternate_outlined),
                              label: Text(_isUploadingImage ? 'Subiendo a KV...' : 'Subir Fotos'),
                              onPressed: _isUploadingImage ? null : _pickAndUploadImages,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_uploadedImageUrls.length} foto(s) añadidas',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        if (_uploadedImageUrls.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _uploadedImageUrls.map((url) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 30),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _uploadedImageUrls.remove(url);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description (English - Optional)
                  Text('Descripción en Inglés (Opcional)', style: AppTextStyles.subtitle2),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descEnController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'English description for international clients...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Price & Price Type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Precio (COP)', style: AppTextStyles.subtitle2),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: '\$ ',
                                hintText: '150000',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tipo de precio', style: AppTextStyles.subtitle2),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _priceType,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'fixed', child: Text('Fijo')),
                                DropdownMenuItem(value: 'hourly', child: Text('Por hora')),
                                DropdownMenuItem(value: 'daily', child: Text('Por día')),
                                DropdownMenuItem(value: 'negotiable', child: Text('A convenir')),
                              ],
                              onChanged: (val) => setState(() => _priceType = val ?? 'fixed'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // City
                  Text('Ciudad *', style: AppTextStyles.subtitle2),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _cities
                        .map((c) => DropdownMenuItem(
                              value: c['id']!,
                              child: Text(c['name']!),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCity = val ?? 'bogota'),
                  ),
                  const SizedBox(height: 20),

                  // WhatsApp
                  Text('Número de WhatsApp', style: AppTextStyles.subtitle2),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                      hintText: '+57 300 123 4567',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Publicar Anuncio Ahora',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
