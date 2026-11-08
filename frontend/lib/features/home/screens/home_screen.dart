import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/category.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/listing_card.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../listings/providers/listings_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final featuredListings = ref.watch(featuredListingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront, color: AppColors.primary),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Marketplace de Colombia',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
            tooltip: 'Buscar',
          ),
          if (!isAuthenticated)
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Entrar'),
            )
          else
            IconButton(
              icon: const Icon(Icons.person_outlined),
              onPressed: () => context.go('/profile'),
              tooltip: 'Mi perfil',
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: isDesktop
          ? null
          : const AppBottomNav(currentIndex: 0),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 240,
              child: const AppDrawer(),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  _HeroSection(isDesktop: isDesktop),

                  // Categories Grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Categorías',
                              style: AppTextStyles.headlineSmall,
                            ),
                            TextButton(
                              onPressed: () => context.go('/listings'),
                              child: const Text('Ver todo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        categoriesAsync.when(
                          data: (categories) => GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: isDesktop ? 6 : 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                            children: categories
                                .map((cat) => _CategoryCard(category: cat))
                                .toList(),
                          ),
                          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                  ),

                  // Featured Listings
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Anuncios Destacados',
                              style: AppTextStyles.headlineSmall,
                            ),
                            TextButton(
                              onPressed: () => context.go('/listings'),
                              child: const Text('Ver más'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280,
                          child: featuredListings.when(
                            loading: () => ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 4,
                              itemBuilder: (_, __) => const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: SizedBox(
                                    width: 220,
                                    child: ListingCardShimmer()),
                              ),
                            ),
                            error: (e, _) => EmptyState(
                              icon: Icons.error_outline,
                              title: 'Error al cargar',
                              subtitle: e.toString(),
                            ),
                            data: (listings) {
                              if (listings.isEmpty) {
                                return const EmptyState(
                                  icon: Icons.list_alt_outlined,
                                  title: 'Sin anuncios destacados',
                                );
                              }
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: listings.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (_, i) => SizedBox(
                                  width: 220,
                                  child: ListingCard(listing: listings[i]),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map CTA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Busca en el Mapa',
                                  style: AppTextStyles.titleLarge
                                      .copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Encuentra servicios cerca de ti',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                  ),
                                  onPressed: () => context.go('/map'),
                                  child: const Text('Ver Mapa'),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.map_outlined,
                            size: 80,
                            color: Colors.white24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Help Requests CTA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Necesitas Ayuda?',
                                  style: AppTextStyles.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Publica lo que necesitas y recibe ofertas de proveedores',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                  ),
                                  onPressed: () => context.go('/requests'),
                                  child: const Text('Solicitar Ayuda'),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.support_agent_outlined,
                            size: 64,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatefulWidget {
  final bool isDesktop;
  const _HeroSection({required this.isDesktop});

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: widget.isDesktop ? 64 : 40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0D47A1)],
        ),
      ),
      child: Column(
        children: [
          Text(
            'El Marketplace de Colombia',
            style: (widget.isDesktop
                    ? AppTextStyles.headlineLarge
                    : AppTextStyles.headlineMedium)
                .copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Encuentra servicios, vivienda, empleos y más',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: widget.isDesktop ? 600 : double.infinity),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Buscar servicios, vivienda...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (q) {
                      if (q.isNotEmpty) {
                        context.go('/search?q=$q');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  onPressed: () {
                    final q = _searchController.text;
                    if (q.isNotEmpty) {
                      context.go('/search?q=$q');
                    } else {
                      context.go('/search');
                    }
                  },
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _QuickTag('Plomería', Icons.plumbing),
              _QuickTag('Arriendos', Icons.home),
              _QuickTag('Empleos', Icons.work),
              _QuickTag('Moto', Icons.two_wheeler),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTag extends StatelessWidget {
  final String label;
  final IconData icon;
  const _QuickTag(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/search?q=$label'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/listings?category=${category.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: Icon(category.materialIcon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              category.nameEs,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
