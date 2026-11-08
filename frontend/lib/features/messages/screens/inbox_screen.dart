import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/empty_state.dart';

final inboxMessagesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get<Map<String, dynamic>>('/messages');
  final data = response.data!;
  return (data['data'] as List<dynamic>?) ?? [];
});

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final conversationsAsync = ref.watch(inboxMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes en Tiempo Real'),
      ),
      bottomNavigationBar: !isDesktop ? const AppBottomNav(currentIndex: 3) : null,
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No tienes mensajes aún',
              message: 'Cuando contactes a un proveedor o te escriban por tus anuncios, aparecerán aquí en tiempo real.',
              buttonText: 'Explorar Anuncios',
              onAction: () => context.go('/listings'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(inboxMessagesProvider),
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = conversations[index] as Map<String, dynamic>;
                final otherUserId = item['other_user_id']?.toString() ?? '';
                final name = item['other_user_name']?.toString() ?? 'Usuario';
                final lastMessage = item['last_message']?.toString() ?? '';
                final unread = ((item['unread_count'] as num?)?.toInt() ?? 0) > 0;
                final avatar = item['other_user_avatar']?.toString();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: avatar != null && avatar.startsWith('http')
                        ? ClipOval(child: Image.network(avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text(name.isNotEmpty ? name[0] : 'U')))
                        : Text(name.isNotEmpty ? name[0] : 'U', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(
                    name,
                    style: unread ? AppTextStyles.subtitle1 : AppTextStyles.bodyLarge,
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                      color: unread ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                  onTap: () => context.go('/messages/$otherUserId'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error al cargar mensajes: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(inboxMessagesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
