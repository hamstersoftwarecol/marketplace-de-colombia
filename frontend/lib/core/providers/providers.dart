import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/help_request.dart';

// Storage Service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// API Service
final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiService(storage);
});

// Auth Service
final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthService(api, storage);
});

// Listing Service
final listingServiceProvider = Provider<ListingService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ListingService(api);
});

// Categories Provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.watch(listingServiceProvider);
  return service.getCategories();
});

// Requests Provider
final requestsProvider = FutureProvider<List<HelpRequest>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get<Map<String, dynamic>>('/requests');
  final data = response.data!;
  final items = data['data'] as List<dynamic>? ?? [];
  return items.map((e) => HelpRequest.fromJson(e as Map<String, dynamic>)).toList();
});

// Current auth user state
final currentUserProvider = StateProvider<User?>((ref) => null);

// Is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
