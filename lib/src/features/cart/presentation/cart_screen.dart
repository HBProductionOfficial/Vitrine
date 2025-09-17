import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/state_views.dart';
import '../../shop/presentation/widgets/product_image.dart';
import '../domain/cart.dart';
import 'cart_controller.dart';
import 'widgets/checkout_sheet.dart';
import 'widgets/quantity_stepper.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cart = ref.watch(cartProvider);

    // Its own messenger, so the undo snack bar sits above the totals instead of covering them.
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: PageAppBar(
          maxWidth: 760,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cartTitle),
              if (!cart.isEmpty)
                RollingText(
                  l10n.itemsCount(cart.count),
                  style: Theme.of(context).textTheme.bodySmall,
                  alignment: Alignment.centerLeft,
                ),
            ],
          ),
        ),
        body: AnimatedSwitcher(
          duration: Motion.slow,
          child: cart.isEmpty
              ? FadeSlideIn(
                  key: const ValueKey('empty'),
                  child: MessageView(
                    icon: Icons.shopping_bag_outlined,
                    title: l10n.cartEmptyTitle,
                    message: l10n.cartEmptyBody,
                    action: ScaleOnPress(
                      builder: (states) => FilledButton(
                        statesController: states,
                        onPressed: () => context.go(Routes.shop),
                        child: Text(l10n.browseShop),
                      ),
                    ),
                  ),
                )
              : PageBody(
                  key: const ValueKey('list'),
                  maxWidth: 760,
                  // A plain children list, so lines keep their state by key
                  // when one above them is removed or put back.
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(Insets.page, Insets.sm, Insets.page, Insets.xl),
                    children: [
                      for (final (i, item) in cart.items.indexed)
                        FadeSlideIn(
                          key: ValueKey(item.product.id),
                          delay: FadeSlideIn.stagger(i),
                          child: _CartLine(item: item),
                        ),
                    ],
                  ),
                ),
        ),
        bottomNavigationBar: cart.isEmpty ? null : _Summary(cart: cart),
      ),
    );
  }
}

void _removeWithUndo(BuildContext context, WidgetRef ref, CartItem item) {
  final l10n = AppLocalizations.of(context);
  // Keep the notifier, not the ref: the line's widget is gone by the time Undo is tapped.
  final cart = ref.read(cartProvider.notifier);
  final removed = cart.remove(item.product.id);
  if (removed == null) return;
  showSnack(
    context,
    l10n.removedFromCart(item.product.title),
    action: SnackBarAction(label: l10n.undo, onPressed: () => cart.restore(removed.$1, removed.$2)),
  );
}

class _CartLine extends ConsumerStatefulWidget {
  const _CartLine({required this.item});

  final CartItem item;

  @override
  ConsumerState<_CartLine> createState() => _CartLineState();
}

class _CartLineState extends ConsumerState<_CartLine> with SingleTickerProviderStateMixin {
  late final _presence = AnimationController(vsync: this, duration: Motion.slow, value: 1);
  late final _curve = CurvedAnimation(parent: _presence, curve: Motion.move);

  @override
  void dispose() {
    _curve.dispose();
    _presence.dispose();
    super.dispose();
  }

  /// The bin button folds the line away first, so the list closes the gap
  /// smoothly instead of jumping.
  Future<void> _remove() async {
    if (!reduceMotion(context)) await _presence.reverse();
    if (mounted) _removeWithUndo(context, ref, widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final item = widget.item;
    final product = item.product;
    final controller = ref.read(cartProvider.notifier);

    final line = Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeWithUndo(context, ref, item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Insets.xl),
        decoration: BoxDecoration(color: p.dangerSoft, borderRadius: BorderRadius.circular(Corners.card)),
        child: Icon(Icons.delete_outline_rounded, color: p.danger),
      ),
      child: Pressable(
        color: p.surface,
        ripple: true,
        scale: 0.98,
        onTap: () => context.push(Routes.product(product.id, from: Routes.cart)),
        child: Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 84,
                child: ExcludeSemantics(
                  child: ProductImage(url: product.thumbnail, padding: Insets.sm, radius: Corners.input),
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: p.ink, height: 1.35),
                    ),
                    Text(formatPrice(context, product.finalPrice), style: theme.textTheme.bodySmall),
                    const SizedBox(height: Insets.sm),
                    Row(
                      children: [
                        QuantityStepper(
                          quantity: item.quantity,
                          max: controller.limitFor(product),
                          onChanged: (q) => controller.setQuantity(product.id, q),
                          onRemove: _remove,
                        ),
                        const Spacer(),
                        RollingText(formatPrice(context, item.lineTotal), style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return SizeTransition(
      sizeFactor: _curve,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _curve,
        child: Padding(
          padding: const EdgeInsets.only(bottom: Insets.sm),
          child: line,
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final theme = Theme.of(context);

    Widget row(String label, String value, {TextStyle? style, Color? valueColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style ?? theme.textTheme.bodyMedium)),
          RollingText(value, style: (style ?? theme.textTheme.bodyMedium)?.copyWith(color: valueColor ?? p.ink)),
        ],
      ),
    );

    return ColoredBox(
      color: p.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          PageBody(
            maxWidth: 760,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Insets.page, Insets.lg, Insets.page, Insets.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  row(l10n.subtotal, formatPrice(context, cart.subtotal)),
                  if (cart.discount > 0) row(l10n.discount, formatPrice(context, -cart.discount), valueColor: p.accent),
                  const SizedBox(height: Insets.xs),
                  row(l10n.total, formatPrice(context, cart.total), style: theme.textTheme.titleMedium),
                  const SizedBox(height: Insets.md),
                  PrimaryButton(
                    label: l10n.checkout,
                    onPressed: () => showAppSheet<void>(context, builder: (_) => const CheckoutSheet()),
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
