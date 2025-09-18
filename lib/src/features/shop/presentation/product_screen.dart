import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/tokens.dart';
import '../../../core/errors.dart';
import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../cart/presentation/widgets/quantity_stepper.dart';
import '../../reviews/my_reviews_controller.dart';
import '../../reviews/review_sheet.dart';
import '../../saved/presentation/save_button.dart';
import '../../saved/presentation/saved_controller.dart';
import '../data/dummy_json_products_repository.dart';
import '../domain/product.dart';
import 'shop_controller.dart';
import 'widgets/product_image.dart';

final productProvider = FutureProvider.autoDispose.family<Product, int>(
  (ref, id) => ref.watch(productsRepositoryProvider).product(id),
);

class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key, required this.id, this.heroScope = Routes.shop});

  final int id;

  /// Which list the page was opened from, so the image flies in from there.
  final String heroScope;

  /// The list we came from already has most of the product, so show that
  /// straight away (and let the Hero land) while the full record loads.
  Product? _preview(WidgetRef ref) {
    bool match(Product p) => p.id == id;
    return ref.read(shopControllerProvider).products.where(match).firstOrNull ??
        ref.read(savedProvider).where(match).firstOrNull ??
        ref.read(cartProvider).items.map((i) => i.product).where(match).firstOrNull;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(productProvider(id));
    final product = async.value ?? _preview(ref);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: async.hasError
            ? ErrorView(message: describeError(async.error!, l10n), onRetry: () => ref.invalidate(productProvider(id)))
            : const Center(child: CircularProgressIndicator()),
      );
    }

    // Its own messenger, so snack bars sit above the buy bar instead of covering it.
    return ScaffoldMessenger(
      child: Scaffold(
        // The content below has no padding of its own, hence the extra page insets.
        appBar: PageAppBar(
          maxWidth: Breakpoints.contentMaxWidth + 2 * Insets.page,
          actions: [SaveButton(product: product)],
        ),
        bottomNavigationBar: _BuyBar(product: product),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = pageGutter(constraints.maxWidth);
            final details = _Details(product: product, loading: async.isLoading);
            if (constraints.maxWidth < Breakpoints.medium) {
              return ListView(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, Insets.xxl),
                children: [
                  // Keep the gallery from filling a landscape phone.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _Gallery(product: product, heroScope: heroScope),
                    ),
                  ),
                  const SizedBox(height: Insets.xl),
                  details,
                ],
              );
            }
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(gutter, Insets.sm, gutter, Insets.xxl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _Gallery(product: product, heroScope: heroScope),
                  ),
                  const SizedBox(width: Insets.xxl),
                  Expanded(flex: 6, child: details),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.product, required this.heroScope});

  final Product product;
  final String heroScope;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _pages = PageController();
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // PageView only builds the page on screen, so fetch the rest now and a
    // swipe doesn't land on an empty tile.
    for (final url in widget.product.gallery.skip(1)) {
      unawaited(precacheImage(CachedNetworkImageProvider(url), context));
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final product = widget.product;
    final images = product.gallery;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: _pages,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final image = Semantics(
                image: true,
                label: l10n.imageOf(i + 1, images.length),
                child: ProductImage(
                  url: images[i],
                  placeholderUrl: i == 0 ? product.thumbnail : null,
                  padding: Insets.xl,
                ),
              );
              return i == 0 ? Hero(tag: productHeroTag(product.id, widget.heroScope), child: image) : image;
            },
          ),
        ),
        if (images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < images.length; i++)
                Semantics(
                  button: true,
                  selected: i == _index,
                  label: l10n.imageOf(i + 1, images.length),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pages.animateToPage(i, duration: Motion.slow, curve: Motion.move),
                    // The dot is small; the tap area around it is not.
                    child: SizedBox(
                      width: 28,
                      height: 44,
                      child: Center(
                        child: AnimatedContainer(
                          duration: Motion.base,
                          curve: Motion.move,
                          width: i == _index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _index ? p.ink : p.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.product, required this.loading});

  final Product product;

  /// The full record (description, reviews) is still on its way.
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final theme = Theme.of(context);

    final categoryName =
        ref.watch(categoriesProvider).value?.where((c) => c.slug == product.category).firstOrNull?.name ??
        product.category;
    final kicker = [?product.brand, if (categoryName.isNotEmpty) categoryName].join('  ·  ');
    final mine = ref.watch(myReviewsProvider.select((all) => all[product.id]));
    final reviewCount = product.reviews.length + (mine == null ? 0 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kicker.isNotEmpty) Text(kicker, style: theme.textTheme.bodySmall),
        const SizedBox(height: Insets.xs),
        Text(product.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: Insets.sm),
        Row(
          children: [
            _Stars(rating: product.rating),
            const SizedBox(width: 6),
            Text(product.rating.toStringAsFixed(1), style: theme.textTheme.labelMedium),
            if (!loading || reviewCount > 0)
              Text('  ·  ${l10n.reviewsCount(reviewCount)}', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: Insets.lg),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Insets.sm,
          children: [
            Text(formatPrice(context, product.finalPrice), style: theme.textTheme.headlineMedium),
            if (product.percentOff > 0) ...[
              Text(
                formatPrice(context, product.price),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: p.inkFaint,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: p.inkFaint,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  l10n.percentOff(product.percentOff),
                  style: theme.textTheme.labelSmall?.copyWith(color: p.accent),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Insets.sm),
        _StockLine(stock: product.stock),
        const SizedBox(height: Insets.xl),
        Text(l10n.aboutProduct, style: theme.textTheme.titleMedium),
        const SizedBox(height: Insets.sm),
        if (product.description.isEmpty && loading)
          const Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(),
                SizedBox(height: Insets.sm),
                SkeletonBox(),
                SizedBox(height: Insets.sm),
                SkeletonBox(width: 180),
              ],
            ),
          )
        else
          Text(product.description, style: theme.textTheme.bodyLarge?.copyWith(color: p.inkSoft)),
        const SizedBox(height: Insets.lg),
        _Fact(icon: Icons.sell_outlined, label: l10n.brandLabel, value: product.brand),
        _Fact(icon: Icons.local_shipping_outlined, label: l10n.shippingInfo, value: product.shipping),
        _Fact(icon: Icons.verified_outlined, label: l10n.warrantyInfo, value: product.warranty),
        _Fact(icon: Icons.undo_rounded, label: l10n.returnsInfo, value: product.returnPolicy),
        const SizedBox(height: Insets.xl),
        Row(
          children: [
            Expanded(child: Text(l10n.reviewsTitle(reviewCount), style: theme.textTheme.titleMedium)),
            if (mine == null)
              TextButton.icon(
                style: TextButton.styleFrom(textStyle: theme.textTheme.labelLarge),
                onPressed: () => _openReviewSheet(context, product),
                icon: const Icon(Icons.rate_review_outlined, size: 20),
                label: Text(l10n.writeReview),
              ),
          ],
        ),
        const SizedBox(height: Insets.sm),
        AnimatedSize(
          duration: Motion.slow,
          curve: Motion.move,
          alignment: Alignment.topCenter,
          child: mine == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: FadeSlideIn(
                    child: _ReviewTile(review: mine, product: product, mine: true),
                  ),
                ),
        ),
        if (reviewCount == 0 && !loading)
          Text(l10n.noReviews, style: theme.textTheme.bodyMedium)
        else
          for (final review in product.reviews) ...[_ReviewTile(review: review), const SizedBox(height: Insets.sm)],
      ],
    );
  }
}

class _StockLine extends StatelessWidget {
  const _StockLine({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final (icon, text, color) = switch (stock) {
      0 => (Icons.block_rounded, l10n.outOfStock, p.danger),
      <= 5 => (Icons.error_outline_rounded, l10n.lowStock(stock), p.danger),
      _ => (Icons.check_circle_outline_rounded, l10n.inStock(stock), p.success),
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final p = context.palette;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: p.inkFaint),
          const SizedBox(width: Insets.md),
          SizedBox(width: 96, child: Text(label, style: theme.textTheme.bodyMedium)),
          Expanded(
            child: Text(value!, style: theme.textTheme.bodyMedium?.copyWith(color: p.ink)),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 18});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = context.palette.inkSoft;
    return Semantics(
      label: l10n.ratingLabel(rating.toStringAsFixed(1)),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              rating >= i
                  ? Icons.star_rounded
                  : rating >= i - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: color,
            ),
        ],
      ),
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({required this.review, this.product, this.mine = false});

  final Review review;

  /// Needed for your own review, which can be edited and deleted.
  final Product? product;
  final bool mine;

  void _delete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reviews = ref.read(myReviewsProvider.notifier);
    final id = product!.id;
    final removed = reviews.remove(id);
    if (removed == null) return;
    showSnack(
      context,
      l10n.reviewDeleted,
      action: SnackBarAction(label: l10n.undo, onPressed: () => reviews.restore(id, removed)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, mine ? Insets.xs : Insets.lg),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(Corners.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: Text(review.reviewer, style: theme.textTheme.titleSmall)),
              if (mine) ...[
                const SizedBox(width: Insets.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(6)),
                  child: Text(l10n.reviewYou, style: theme.textTheme.labelSmall?.copyWith(color: p.onInk)),
                ),
              ],
              const Spacer(),
              _Stars(rating: review.rating.toDouble(), size: 15),
            ],
          ),
          if (review.date != null)
            Text(DateFormat.yMMMd(locale).format(review.date!.toLocal()), style: theme.textTheme.bodySmall),
          const SizedBox(height: Insets.sm),
          Text(review.comment, style: theme.textTheme.bodyMedium?.copyWith(color: p.ink)),
          if (mine)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(textStyle: theme.textTheme.labelLarge),
                  onPressed: () => _openReviewSheet(context, product!, existing: review),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.edit),
                ),
                TextButton.icon(
                  onPressed: () => _delete(context, ref),
                  style: TextButton.styleFrom(foregroundColor: p.danger, textStyle: theme.textTheme.labelLarge),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(l10n.delete),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

Future<void> _openReviewSheet(BuildContext context, Product product, {Review? existing}) async {
  final message = AppLocalizations.of(context).reviewSaved;
  final saved = await showAppSheet<bool>(
    context,
    builder: (_) => ReviewSheet(product: product, existing: existing),
  );
  if ((saved ?? false) && context.mounted) showSnack(context, message);
}

class _BuyBar extends ConsumerStatefulWidget {
  const _BuyBar({required this.product});

  final Product product;

  @override
  ConsumerState<_BuyBar> createState() => _BuyBarState();
}

class _BuyBarState extends ConsumerState<_BuyBar> {
  /// How many to add, while the product isn't in the cart yet.
  int _amount = 1;
  Timer? _confirm;

  @override
  void dispose() {
    _confirm?.cancel();
    super.dispose();
  }

  void _add() {
    if (!ref.read(cartProvider.notifier).add(widget.product, quantity: _amount)) return;
    // A tick on the button for a moment, then it turns into "View cart".
    _confirm?.cancel();
    _confirm = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _confirm = null);
    });
    setState(() => _amount = 1);
  }

  void _remove() {
    final l10n = AppLocalizations.of(context);
    final cart = ref.read(cartProvider.notifier);
    final removed = cart.remove(widget.product.id);
    if (removed == null) return;
    showSnack(
      context,
      l10n.removedFromCart(widget.product.title),
      action: SnackBarAction(label: l10n.undo, onPressed: () => cart.restore(removed.$1, removed.$2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final product = widget.product;
    final cart = ref.read(cartProvider.notifier);
    final inCart = ref.watch(cartProvider.select((c) => c.quantityOf(product.id)));
    final limit = cart.limitFor(product);
    final justAdded = _confirm != null;

    // Out of stock: nothing to pick. In the cart: the stepper edits the cart
    // line itself. Otherwise it picks how many the button adds.
    final Widget? stepper = !product.inStock
        ? null
        : inCart > 0
        ? QuantityStepper(
            key: const ValueKey('cart'),
            size: 52,
            quantity: inCart,
            max: limit,
            onChanged: (q) => cart.setQuantity(product.id, q),
            onRemove: _remove,
          )
        : QuantityStepper(
            key: const ValueKey('pick'),
            size: 52,
            quantity: _amount,
            max: limit,
            onChanged: (q) => setState(() => _amount = q),
          );

    final PrimaryButton button;
    if (justAdded) {
      button = PrimaryButton(accent: true, icon: Icons.check_rounded, label: l10n.addedToCart, onPressed: () {});
    } else if (inCart > 0) {
      button = PrimaryButton(
        icon: Icons.shopping_bag_outlined,
        label: l10n.viewCart,
        onPressed: () => GoRouter.of(context).go(Routes.cart),
      );
    } else {
      button = PrimaryButton(
        accent: true,
        icon: Icons.add_shopping_cart_rounded,
        label: product.inStock ? l10n.addToCart : l10n.outOfStock,
        onPressed: product.inStock ? _add : null,
      );
    }

    return ColoredBox(
      color: p.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          PageBody(
            maxWidth: 760,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Insets.page, Insets.md, Insets.page, Insets.md),
              child: Row(
                children: [
                  if (stepper != null) ...[
                    AnimatedSwitcher(duration: Motion.base, child: stepper),
                    const SizedBox(width: Insets.md),
                  ],
                  Expanded(child: button),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
