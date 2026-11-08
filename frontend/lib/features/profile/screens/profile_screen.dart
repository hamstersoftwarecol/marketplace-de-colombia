import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/profile/edit'),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop ? const AppBottomNav(currentIndex: 4) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info header
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.name ?? 'Usuario', style: AppTextStyles.h3),
                              const SizedBox(height: 4),
                              Text(user?.email ?? 'usuario@marketplace.com', style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Plan ${user?.plan.toUpperCase() ?? 'GRATIS'}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (user?.isVerified == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '✓ Verificado',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => context.go('/profile/edit'),
                          child: const Text('Editar'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Menu items
                Text('Mi Cuenta', style: AppTextStyles.h4),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: Icons.list_alt_outlined,
                  title: 'Mis Anuncios',
                  subtitle: 'Gestiona tus publicaciones activas o pausadas',
                  onTap: () => context.go('/listings'),
                ),
                _buildMenuTile(
                  icon: Icons.favorite_border,
                  title: 'Favoritos',
                  subtitle: 'Anuncios que has guardado',
                  onTap: () => context.go('/listings'),
                ),
                _buildMenuTile(
                  icon: Icons.help_outline,
                  title: 'Mis Solicitudes',
                  subtitle: 'Revisa tus solicitudes de ayuda abiertas',
                  onTap: () => context.go('/requests'),
                ),
                _buildMenuTile(
                  icon: Icons.star_outline,
                  title: 'Mis Reseñas',
                  subtitle: 'Opiniones y calificaciones recibidas',
                  onTap: () {},
                ),

                const SizedBox(height: 24),
                Text('Configuración', style: AppTextStyles.h4),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: Icons.language_outlined,
                  title: 'Idioma / Language',
                  subtitle: 'Español (Colombia)',
                  onTap: () {},
                ),
                _buildMenuTile(
                  icon: Icons.security_outlined,
                  title: 'Seguridad & Contraseña',
                  subtitle: 'Actualizar contraseña y sesiones activas',
                  onTap: () {},
                ),

                const SizedBox(height: 24),
                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.subtitle2),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}
