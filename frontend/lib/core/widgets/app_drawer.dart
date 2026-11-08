import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../providers/providers.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAuth = ref.watch(isAuthenticatedProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          isAuth ? user!.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              fontSize: 24, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  isAuth ? user!.name : 'Bienvenido',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                if (isAuth)
                  Text(
                    user!.email,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.home_outlined,
            label: 'Inicio',
            onTap: () => _navigate(context, '/'),
          ),
          _DrawerItem(
            icon: Icons.list_alt_outlined,
            label: 'Anuncios',
            onTap: () => _navigate(context, '/listings'),
          ),
          _DrawerItem(
            icon: Icons.map_outlined,
            label: 'Mapa',
            onTap: () => _navigate(context, '/map'),
          ),
          _DrawerItem(
            icon: Icons.help_outline,
            label: 'Solicitudes de Ayuda',
            onTap: () => _navigate(context, '/requests'),
          ),
          const Divider(),
          if (isAuth) ...[
            _DrawerItem(
              icon: Icons.add_circle_outline,
              label: 'Publicar Anuncio',
              onTap: () => _navigate(context, '/listings/create'),
            ),
            _DrawerItem(
              icon: Icons.message_outlined,
              label: 'Mensajes',
              onTap: () => _navigate(context, '/messages'),
            ),
            _DrawerItem(
              icon: Icons.person_outlined,
              label: 'Mi Perfil',
              onTap: () => _navigate(context, '/profile'),
            ),
            const Divider(),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              color: AppColors.error,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
            ),
          ] else ...[
            _DrawerItem(
              icon: Icons.login,
              label: 'Iniciar Sesión',
              onTap: () => _navigate(context, '/login'),
            ),
            _DrawerItem(
              icon: Icons.person_add_outlined,
              label: 'Registrarse',
              onTap: () => _navigate(context, '/register'),
            ),
          ],
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String path) {
    Navigator.pop(context);
    context.go(path);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
