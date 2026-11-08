import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/auth_service.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  late AuthService _authService;

  @override
  Future<User?> build() async {
    _authService = ref.watch(authServiceProvider);
    return _authService.getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.login(email, password);
      ref.read(currentUserProvider.notifier).state = user;
      return user;
    });
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.register(name, email, password);
      ref.read(currentUserProvider.notifier).state = user;
      return user;
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _authService.logout();
      ref.read(currentUserProvider.notifier).state = null;
      return null;
    });
  }

  Future<void> loadCurrentUser() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.getCurrentUser();
      ref.read(currentUserProvider.notifier).state = user;
      return user;
    });
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);
