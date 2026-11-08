import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/listing.dart';
import 'loading_shimmer.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;

  const ListingCard({super.key, required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final firstImage = listing.imageUrls.isNotEmpty ? listing.imageUrls.first.trim() : '';
    final hasValidImage = firstImage.isNotEmpty && firstImage.startsWith('http');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.go('/listings/${listing.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasValidImage
                      ? Image.network(
                          firstImage,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const LoadingShimmer();
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.image_outlined,
                                size: 48, color: AppColors.textHint),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.image_outlined,
                              size: 48, color: AppColors.textHint),
                        ),
                  if (listing.isFeatured)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DESTACADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.formattedPrice,
                    style: AppTextStyles.priceStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Location & rating row
                  Row(
                    children: [
                      if (listing.cityName != null) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            listing.cityName!,
                            style: AppTextStyles.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (listing.avgRating != null) ...[
                        const Icon(Icons.star, size: 12, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          listing.avgRating!.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall,
                        ),
                        Text(
                          ' (${listing.reviewCount})',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.visibility_outlined,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Text(
                        '${listing.views}',
                        style: AppTextStyles.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        timeago.format(listing.createdAt, locale: 'es'),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
