import '../constants/api_constants.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService(this._apiService, this._storageService);

  Future<User> login(String email, String password) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final body = response.data!;
    final payload = (body['data'] ?? body) as Map<String, dynamic>;
    final token = payload['token'] as String;
    await _storageService.saveToken(token);
    final user = User.fromJson(payload['user'] as Map<String, dynamic>);
    await _storageService.saveUser(user);
    return user;
  }

  Future<User> register(String name, String email, String password) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {'name': name, 'email': email, 'password': password},
    );
    final body = response.data!;
    final payload = (body['data'] ?? body) as Map<String, dynamic>;
    final token = payload['token'] as String;
    await _storageService.saveToken(token);
    final user = User.fromJson(payload['user'] as Map<String, dynamic>);
    await _storageService.saveUser(user);
    return user;
  }

  Future<void> logout() async {
    try {
      await _apiService.post<void>(ApiConstants.logout);
    } catch (_) {
      // Even if the API call fails, clear local storage
    } finally {
      await _storageService.clearAll();
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }
      final response = await _apiService.get<Map<String, dynamic>>(ApiConstants.me);
      final body = response.data;
      if (body == null || body['data'] == null) {
        return null;
      }
      final user = User.fromJson(body['data'] as Map<String, dynamic>);
      await _storageService.saveUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }
}
