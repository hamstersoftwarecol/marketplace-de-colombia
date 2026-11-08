import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../listings/providers/listings_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
  }

  final List<String> _popularSearches = [
    'Mudanzas',
    'Acarreos Bogotá',
    'Limpieza profunda',
    'Plomero urgente',
    'Arriendo apartamento',
    'Electricista',
    'Pintor de interiores',
    'Conductor con furgón',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    ref.read(listingsProvider.notifier).applyFilter(ListingsFilter(search: query.trim()));
    context.go('/listings');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda'),
      ),
      bottomNavigationBar: !isDesktop ? const AppBottomNav(currentIndex: 2) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '¿Qué estás buscando hoy?',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => _search(_searchController.text),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onSubmitted: _search,
                ),
                const SizedBox(height: 28),
                Text('Búsquedas populares', style: AppTextStyles.h4),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _popularSearches
                      .map(
                        (term) => ActionChip(
                          avatar: const Icon(Icons.trending_up, size: 16, color: AppColors.primary),
                          label: Text(term),
                          onPressed: () => _search(term),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 36),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: AppColors.surfaceVariant.withOpacity(0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline, size: 40, color: AppColors.secondary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('¿No encuentras lo que buscas?', style: AppTextStyles.subtitle1),
                              const SizedBox(height: 4),
                              Text(
                                'Publica una solicitud en "Necesito Ayuda" y deja que los proveedores te contacten.',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => context.go('/requests/create'),
                          child: const Text('Solicitar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
