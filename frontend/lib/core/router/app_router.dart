import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/listings/screens/listings_screen.dart';
import '../../features/listings/screens/listing_detail_screen.dart';
import '../../features/listings/screens/create_listing_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/messages/screens/inbox_screen.dart';
import '../../features/messages/screens/conversation_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/requests/screens/requests_screen.dart';
import '../../features/requests/screens/create_request_screen.dart';
import '../../features/map/screens/map_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final protectedPaths = [
        '/messages',
        '/profile',
        '/profile/edit',
        '/listings/create',
        '/requests/create',
      ];

      final isProtected = protectedPaths.any(
        (path) => state.matchedLocation.startsWith(path),
      );

      if (isProtected && !isAuthenticated) {
        return '/login?redirect=${state.matchedLocation}';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/listings',
        name: 'listings',
        builder: (context, state) => ListingsScreen(
          categoryId: state.uri.queryParameters['categoryId'],
          search: state.uri.queryParameters['q'],
        ),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-listing',
            builder: (context, state) => const CreateListingScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'listing-detail',
            builder: (context, state) =>
                ListingDetailScreen(listingId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => SearchScreen(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(
        path: '/messages',
        name: 'inbox',
        builder: (context, state) => const InboxScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'conversation',
            builder: (context, state) => ConversationScreen(
              conversationId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/requests',
        name: 'requests',
        builder: (context, state) => const RequestsScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-request',
            builder: (context, state) => const CreateRequestScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
