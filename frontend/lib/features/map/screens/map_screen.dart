import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../listings/providers/listings_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  // Coordinates for major Colombian cities
  final Map<String, LatLng> _cityCoords = {
    'Bogotá': const LatLng(4.7110, -74.0721),
    'Medellín': const LatLng(6.2442, -75.5812),
    'Cali': const LatLng(3.4516, -76.5320),
    'Barranquilla': const LatLng(10.9685, -74.7813),
    'Cartagena': const LatLng(10.3910, -75.4794),
    'Bucaramanga': const LatLng(7.1254, -73.1198),
  };

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar en Mapa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Ver Lista',
            onPressed: () => context.go('/listings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap with flutter_map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(4.7110, -74.0721), // Bogotá default
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.marketplace.web',
              ),
              // Markers from listings
              listingsAsync.when(
                data: (listings) {
                  final validListings = listings.where((l) => l.lat != null && l.lng != null).toList();
                  final markers = validListings.map((l) {
                    return Marker(
                      point: LatLng(l.lat!, l.lng!),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () {
                          _showListingBottomSheet(context, l);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: l.isFeatured ? AppColors.secondary : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
                        ),
                      ),
                    );
                  }).toList();

                  return MarkerLayer(markers: markers);
                },
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),
            ],
          ),

          // City Quick Jump Chips
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _cityCoords.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: Colors.white,
                      elevation: 2,
                      label: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        _mapController.move(entry.value, 12.0);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showListingBottomSheet(BuildContext context, dynamic listing) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(listing.title, style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                listing.price != null ? '\$${listing.price}' : 'Precio a convenir',
                style: AppTextStyles.priceMedium.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                listing.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/listings/${listing.id}');
                  },
                  child: const Text('Ver Anuncio Completo'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
