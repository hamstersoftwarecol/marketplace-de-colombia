import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/listing.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/listing_service.dart';

// Listings filter state
class ListingsFilter {
  final String? categoryId;
  final String? cityId;
  final String? search;
  final double? minPrice;
  final double? maxPrice;
  final String? priceType;
  final bool? featured;
  final int page;

  const ListingsFilter({
    this.categoryId,
    this.cityId,
    this.search,
    this.minPrice,
    this.maxPrice,
    this.priceType,
    this.featured,
    this.page = 1,
  });

  ListingsFilter copyWith({
    String? categoryId,
    String? cityId,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? priceType,
    bool? featured,
    int? page,
    bool clearCategory = false,
    bool clearCity = false,
  }) {
    return ListingsFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      cityId: clearCity ? null : (cityId ?? this.cityId),
      search: search ?? this.search,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      priceType: priceType ?? this.priceType,
      featured: featured ?? this.featured,
      page: page ?? this.page,
    );
  }
}

class ListingsNotifier extends AsyncNotifier<List<Listing>> {
  late ListingService _listingService;
  ListingsFilter _filter = const ListingsFilter();
  final List<Listing> _allListings = [];

  @override
  Future<List<Listing>> build() async {
    _listingService = ref.watch(listingServiceProvider);
    return _fetchListings(reset: true);
  }

  Future<List<Listing>> _fetchListings({bool reset = false}) async {
    if (reset) {
      _allListings.clear();
      _filter = _filter.copyWith(page: 1);
    }
    final listings = await _listingService.getListings(
      categoryId: _filter.categoryId,
      cityId: _filter.cityId,
      search: _filter.search,
      minPrice: _filter.minPrice,
      maxPrice: _filter.maxPrice,
      priceType: _filter.priceType,
      featured: _filter.featured,
      page: _filter.page,
    );
    if (reset) {
      _allListings.addAll(listings);
    } else {
      _allListings.addAll(listings);
    }
    return List.unmodifiable(_allListings);
  }

  Future<void> applyFilter(ListingsFilter filter) async {
    _filter = filter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchListings(reset: true));
  }

  Future<void> loadMore() async {
    _filter = _filter.copyWith(page: _filter.page + 1);
    state = await AsyncValue.guard(() => _fetchListings(reset: false));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchListings(reset: true));
  }

  ListingsFilter get currentFilter => _filter;
}

final listingsProvider = AsyncNotifierProvider<ListingsNotifier, List<Listing>>(
  ListingsNotifier.new,
);

// Single listing detail
final listingDetailProvider =
    FutureProvider.family<Listing, String>((ref, id) async {
  final service = ref.watch(listingServiceProvider);
  return service.getListing(id);
});

// My listings
final myListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final service = ref.watch(listingServiceProvider);
  return service.getMyListings();
});

// Featured listings
final featuredListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final service = ref.watch(listingServiceProvider);
  return service.getListings(featured: true, limit: 10);
});
