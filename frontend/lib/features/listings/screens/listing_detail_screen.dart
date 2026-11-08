import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../providers/listings_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _selectedImageIndex = 0;

  Future<void> _openWhatsApp(String phone, String title) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent('Hola, vi tu anuncio en Marketplace: "$title". ¿Sigue disponible?');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final currencyFmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Anuncio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enlace copiado al portapapeles')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favorito',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guardado en favoritos')),
              );
            },
          ),
        ],
      ),
      body: listingAsync.when(
        data: (listing) {
          final images = listing.imageUrls.isNotEmpty
              ? listing.imageUrls
              : ['https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800'];

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 64 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main layout: Responsive row on desktop, column on mobile
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildGallery(images),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 2,
                            child: _buildActionCard(listing, currencyFmt),
                          ),
                        ],
                      )
                    else ...[
                      _buildGallery(images),
                      const SizedBox(height: 16),
                      _buildActionCard(listing, currencyFmt),
                    ],

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Description section
                    Text('Descripción', style: AppTextStyles.h3),
                    const SizedBox(height: 12),
                    Text(
                      listing.description,
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                    ),

                    if (listing.descriptionEn != null && listing.descriptionEn!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Description (English)', style: AppTextStyles.h4),
                      const SizedBox(height: 8),
                      Text(
                        listing.descriptionEn!,
                        style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Location & Details
                    Text('Información Adicional', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _buildInfoTile(Icons.location_on_outlined, 'Ciudad', listing.cityId ?? 'Colombia'),
                        _buildInfoTile(Icons.visibility_outlined, 'Visitas', '${listing.views} visualizaciones'),
                        _buildInfoTile(Icons.schedule_outlined, 'Tipo de precio', listing.priceType),
                        _buildInfoTile(Icons.star_outline, 'Calificación', '${listing.avgRating ?? 5.0} (${listing.reviewCount} reseñas)'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('No se pudo cargar el anuncio', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(listingDetailProvider(widget.listingId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGallery(List<String> images) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              images[_selectedImageIndex],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const LoadingShimmer();
              },
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image, size: 64, color: AppColors.textHint),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final isSelected = idx == _selectedImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = idx),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      images[idx],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 24),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard(dynamic listing, NumberFormat currencyFmt) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (listing.isFeatured)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DESTACADO',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            Text(listing.title, style: AppTextStyles.h2),
            const SizedBox(height: 12),
            Text(
              listing.price != null
                  ? currencyFmt.format(listing.price)
                  : 'Precio a convenir',
              style: AppTextStyles.priceLarge.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 20),

            // WhatsApp Button
            if (listing.whatsapp != null && listing.whatsapp.toString().isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.chat),
                  label: const Text('Contactar por WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () => _openWhatsApp(listing.whatsapp, listing.title),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // In-app message
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.mail_outline),
                label: const Text('Enviar Mensaje'),
                onPressed: () {
                  context.go('/messages');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.caption),
            Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
