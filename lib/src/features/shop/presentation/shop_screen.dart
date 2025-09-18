import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/design/tokens.dart';
import '../../../core/errors.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/presentation/widgets/quick_add_button.dart';
import '../../saved/presentation/save_button.dart';
import '../../settings/widgets/settings_rows.dart';
import '../domain/product.dart';
import 'shop_controller.dart';
import 'widgets/filter_pill.dart';
import 'widgets/product_card.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _seen = <int>{};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    // Ask for the next page about a screen before the end.
    if (_scroll.position.extentAfter < 800) {
      ref.read(shopControllerProvider.notifier).loadMore();
    }
  }

  void _clearSearch() {
    _search.clear();
    ref.read(shopControllerProvider.notifier).search('', now: true);
  }

  Future<void> _pickSort() async {
    // Otherwise the search field gets focus back, keyboard and all, when the sheet closes.
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context);
    final picked = await showOptionSheet<ProductSort>(
      context,
      title: l10n.sortButton,
      current: ref.read(shopControllerProvider).sort,
      options: [
        for (final (sort, icon) in [
          (ProductSort.recommended, Icons.storefront_outlined),
          (ProductSort.priceLow, Icons.south_rounded),
          (ProductSort.priceHigh, Icons.north_rounded),
          (ProductSort.rating, Icons.star_outline_rounded),
        ])
          SheetOption(value: sort, label: sortLabel(sort, l10n), badgeIcon: icon),
      ],
    );
    if (picked != null) ref.read(shopControllerProvider.notifier).setSort(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(shopControllerProvider);
    final controller = ref.read(shopControllerProvider.notifier);

    // New results start from the top, not wherever the old list was scrolled to.
    ref.listen(shopControllerProvider.select((s) => (s.query, s.category, s.sort)), (_, _) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _seen.clear();
    });

    return Scaffold(
      // The header floats away on scroll; the safe area keeps products from
      // sliding under the status bar once it has.
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = pageGutter(constraints.maxWidth);
            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: CustomScrollView(
                controller: _scroll,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverAppBar(
                    primary: false,
                    floating: true,
                    snap: true,
                    titleSpacing: gutter,
                    title: Text(l10n.shopTitle),
                    actions: [
                      IconButton(
                        tooltip: l10n.savedTitle,
                        onPressed: () => context.push(Routes.saved),
                        icon: const Icon(Icons.favorite_border_rounded),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: gutter - Insets.sm),
                        child: ScaleOnPress(
                          builder: (states) => TextButton.icon(
                            statesController: states,
                            style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
                            onPressed: _pickSort,
                            icon: const Icon(Icons.swap_vert_rounded, size: 20),
                            label: RollingText(sortLabel(state.sort, l10n), alignment: Alignment.centerLeft),
                          ),
                        ),
                      ),
                    ],
                    bottom: _Filters(
                      search: _search,
                      gutter: gutter,
                      // A search covers every category, so the chips step aside.
                      showCategories: state.query.isEmpty,
                      onClear: _clearSearch,
                    ),
                  ),
                  ..._body(state, gutter, l10n),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _body(ShopState state, double gutter, AppLocalizations l10n) {
    final controller = ref.read(shopControllerProvider.notifier);
    if (state.loading && state.products.isEmpty) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, Insets.xs, gutter, 0),
          sliver: const SliverToBoxAdapter(child: _GridSkeleton()),
        ),
      ];
    }
    if (state.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(message: describeError(state.error!, l10n), onRetry: controller.refresh),
        ),
      ];
    }
    if (state.products.isEmpty) {
      final searching = state.query.isNotEmpty;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MessageView(
            icon: Icons.search_off_rounded,
            title: searching ? l10n.noResultsTitle(state.query) : l10n.categoryEmpty,
            message: searching ? l10n.noResultsBody : null,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, Insets.xs, gutter, 0),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) => SliverGrid(
            gridDelegate: productGridDelegate(context, constraints.crossAxisExtent),
            delegate: SliverChildBuilderDelegate((context, i) {
              final product = state.products[i];
              return FadeSlideIn(
                // Each product rises in the first time it shows, a page at a
                // time, and stays put when scrolled back to.
                enabled: _seen.add(product.id),
                delay: FadeSlideIn.stagger(i % ShopController.pageSize),
                child: ProductCard(
                  product: product,
                  action: SaveButton(product: product),
                  cartButton: QuickAddButton(product: product),
                  onTap: () => context.push(Routes.product(product.id)),
                ),
              );
            }, childCount: state.products.length),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _Footer(state: state, onRetry: controller.retryMore),
      ),
    ];
  }
}

String sortLabel(ProductSort sort, AppLocalizations l10n) {
  return switch (sort) {
    ProductSort.recommended => l10n.sortRecommended,
    ProductSort.priceLow => l10n.sortPriceLow,
    ProductSort.priceHigh => l10n.sortPriceHigh,
    ProductSort.rating => l10n.sortRating,
  };
}

class _Filters extends ConsumerWidget implements PreferredSizeWidget {
  const _Filters({required this.search, required this.gutter, required this.showCategories, required this.onClear});

  final TextEditingController search;
  final double gutter;
  final bool showCategories;
  final VoidCallback onClear;

  static const _searchHeight = 64.0;
  static const _chipsHeight = 52.0;

  @override
  Size get preferredSize => Size.fromHeight(_searchHeight + (showCategories ? _chipsHeight : 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(shopControllerProvider.notifier);
    final selected = ref.watch(shopControllerProvider.select((s) => s.category));
    final categories = ref.watch(categoriesProvider).value ?? const <ProductCategory>[];

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, Insets.md),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: search,
            builder: (context, value, _) => TextField(
              controller: search,
              textInputAction: TextInputAction.search,
              onChanged: controller.search,
              onSubmitted: (text) => controller.search(text, now: true),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(tooltip: l10n.clearSearch, onPressed: onClear, icon: const Icon(Icons.close_rounded)),
              ),
            ),
          ),
        ),
        if (showCategories)
          SizedBox(
            height: _chipsHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, Insets.sm),
              itemCount: categories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: Insets.sm),
              itemBuilder: (context, i) {
                final slug = i == 0 ? null : categories[i - 1].slug;
                return Align(
                  alignment: Alignment.topCenter,
                  child: FilterPill(
                    label: i == 0 ? l10n.allCategories : categories[i - 1].name,
                    selected: selected == slug,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      controller.selectCategory(slug);
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final ShopState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(Insets.xl),
        child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.4))),
      );
    }
    if (state.moreError != null) {
      return Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          children: [
            Text(l10n.loadingMoreFailed, style: Theme.of(context).textTheme.bodyMedium),
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      );
    }
    return const SizedBox(height: Insets.xl);
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final delegate = productGridDelegate(context, constraints.maxWidth);
        return Shimmer(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: delegate,
            itemCount: 6,
            itemBuilder: (_, i) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AspectRatio(aspectRatio: 1, child: SkeletonBox(radius: Corners.card)),
                const SizedBox(height: Insets.md),
                SkeletonBox(width: 90.0 + (i % 3) * 24),
                const SizedBox(height: Insets.sm),
                const SkeletonBox(width: 56),
              ],
            ),
          ),
        );
      },
    );
  }
}
