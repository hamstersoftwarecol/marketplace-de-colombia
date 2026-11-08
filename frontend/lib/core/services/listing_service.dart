import 'dart:convert';
import '../constants/api_constants.dart';
import '../models/listing.dart';
import '../models/category.dart';
import 'api_service.dart';

class ListingService {
  final ApiService _apiService;

  ListingService(this._apiService);

  Future<List<Listing>> getListings({
    String? categoryId,
    String? cityId,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? priceType,
    bool? featured,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.listings,
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (cityId != null) 'cityId': cityId,
        if (search != null && search.isNotEmpty) 'q': search,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (priceType != null) 'priceType': priceType,
        if (featured != null) 'featured': featured,
        'page': page,
        'limit': limit,
      },
    );
    final data = response.data!;
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Listing> getListing(String id) async {
    final response =
        await _apiService.get<Map<String, dynamic>>('${ApiConstants.listings}/$id');
    return Listing.fromJson(response.data!);
  }

  Future<List<Listing>> getMyListings() async {
    final response =
        await _apiService.get<Map<String, dynamic>>(ApiConstants.myListings);
    final data = response.data!;
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Listing> createListing(Map<String, dynamic> data) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.listings,
      data: data,
    );
    return Listing.fromJson(response.data!);
  }

  Future<Listing> updateListing(String id, Map<String, dynamic> data) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '${ApiConstants.listings}/$id',
      data: data,
    );
    return Listing.fromJson(response.data!);
  }

  Future<List<Category>> getCategories() async {
    final response = await _apiService.get<Map<String, dynamic>>(ApiConstants.categories);
    final data = response.data!;
    final items = data['data'] as List<dynamic>? ?? [];
    return items.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> uploadImage(List<int> bytes, {String mimeType = 'image/jpeg'}) async {
    final base64Str = base64Encode(bytes);
    final response = await _apiService.post<Map<String, dynamic>>(
      '/uploads',
      data: {
        'image': 'data:$mimeType;base64,$base64Str',
        'contentType': mimeType,
      },
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return data['url'] as String;
  }

  Future<void> deleteListing(String id) async {
    await _apiService.delete<void>('${ApiConstants.listings}/$id');
  }
}
