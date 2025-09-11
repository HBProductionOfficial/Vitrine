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
import '../../../core/widgets/page_body.dart';
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
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cartTitle),
              if (!cart.isEmpty) Text(l10n.itemsCount(cart.count), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        body: cart.isEmpty
            ? MessageView(
                icon: Icons.shopping_bag_outlined,
                title: l10n.cartEmptyTitle,
                message: l10n.cartEmptyBody,
                action: FilledButton(onPressed: () => context.go(Routes.shop), child: Text(l10n.browseShop)),
              )
            : PageBody(
                maxWidth: 760,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(Insets.page, Insets.sm, Insets.page, Insets.xl),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Insets.sm),
                  itemBuilder: (context, i) => _CartLine(item: cart.items[i]),
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

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final theme = Theme.of(context);
    final product = item.product;
    final controller = ref.read(cartProvider.notifier);

    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeWithUndo(context, ref, item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Insets.xl),
        decoration: BoxDecoration(color: p.dangerSoft, borderRadius: BorderRadius.circular(Corners.card)),
        child: Icon(Icons.delete_outline_rounded, color: p.danger),
      ),
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.card),
          side: BorderSide(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
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
                            onRemove: () => _removeWithUndo(context, ref, item),
                          ),
                          const Spacer(),
                          Text(formatPrice(context, item.lineTotal), style: theme.textTheme.titleSmall),
                        ],
                      ),
                    ],
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
          Text(value, style: (style ?? theme.textTheme.bodyMedium)?.copyWith(color: valueColor ?? p.ink)),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: PageBody(
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
    );
  }
}
