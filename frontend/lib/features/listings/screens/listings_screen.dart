import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/category.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/listing_card.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../providers/listings_provider.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? search;

  const ListingsScreen({
    super.key,
    this.categoryId,
    this.search,
  });

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categoryId;
    if (widget.search != null) {
      _searchController.text = widget.search!;
    }

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.categoryId != null || widget.search != null) {
        ref.read(listingsProvider.notifier).applyFilter(
              ListingsFilter(
                categoryId: widget.categoryId,
                search: widget.search,
              ),
            );
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(listingsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Anuncios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Ver en Mapa',
            onPressed: () => context.go('/map'),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Publicar Anuncio',
            onPressed: () => context.go('/listings/create'),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop ? const AppBottomNav(currentIndex: 1) : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
        onPressed: () => context.go('/listings/create'),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar servicios, mudanzas, empleos...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(listingsProvider.notifier).applyFilter(
                                    ListingsFilter(categoryId: _selectedCategory),
                                  );
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (value) {
                    ref.read(listingsProvider.notifier).applyFilter(
                          ListingsFilter(
                            categoryId: _selectedCategory,
                            search: value.trim().isEmpty ? null : value.trim(),
                          ),
                        );
                  },
                ),
                const SizedBox(height: 10),
                // Horizontal category chips
                categoriesAsync.when(
                  data: (categories) => SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        CategoryChip(
                          icon: Icons.apps,
                          label: 'Todos',
                          isSelected: _selectedCategory == null,
                          onSelected: () {
                            setState(() => _selectedCategory = null);
                            ref.read(listingsProvider.notifier).applyFilter(
                                  ListingsFilter(
                                    search: _searchController.text.trim().isEmpty
                                        ? null
                                        : _searchController.text.trim(),
                                  ),
                                );
                          },
                        ),
                        ...categories.map((c) => CategoryChip(
                              icon: c.materialIcon,
                              label: c.nameEs,
                              isSelected: _selectedCategory == c.id,
                              onSelected: () {
                                setState(() => _selectedCategory = c.id);
                                ref.read(listingsProvider.notifier).applyFilter(
                                      ListingsFilter(
                                        categoryId: c.id,
                                        search: _searchController.text.trim().isEmpty
                                            ? null
                                            : _searchController.text.trim(),
                                      ),
                                    );
                              },
                            )),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(height: 38),
                  error: (_, __) => const SizedBox(height: 38),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Listings Grid/List
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No encontramos anuncios',
                    message: 'Intenta con otros términos o cambia la categoría.',
                    buttonText: 'Limpiar Filtros',
                    onAction: () {
                      _searchController.clear();
                      setState(() => _selectedCategory = null);
                      ref.read(listingsProvider.notifier).refresh();
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(listingsProvider.notifier).refresh(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth >= 1200) {
                        crossAxisCount = 4;
                      } else if (constraints.maxWidth >= 800) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth >= 600) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: listings.length,
                        itemBuilder: (context, index) {
                          return ListingCard(listing: listings[index]);
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => const LoadingShimmer(
                  width: double.infinity,
                  height: 250,
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('Error al cargar anuncios', style: AppTextStyles.h4),
                      const SizedBox(height: 6),
                      Text(err.toString(), textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(listingsProvider.notifier).refresh(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
