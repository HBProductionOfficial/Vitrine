import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/state_views.dart';
import '../../shop/presentation/widgets/product_image.dart';
import '../domain/order.dart';
import 'orders_controller.dart';
import 'orders_screen.dart';

class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key, required this.orderRef});

  /// [Order.ref] of the order to show.
  final String orderRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final placed = ref.watch(placedOrdersProvider);
    final history = ref.watch(orderHistoryProvider);
    bool match(Order o) => o.ref == orderRef;
    final order = placed.where(match).firstOrNull ?? history.value?.where(match).firstOrNull;

    if (order == null) {
      return Scaffold(
        appBar: const PageAppBar(maxWidth: 760),
        body: history.isLoading
            ? const Center(child: CircularProgressIndicator())
            : MessageView(icon: Icons.receipt_long_outlined, title: l10n.orderNotFound),
      );
    }

    return Scaffold(
      appBar: PageAppBar(maxWidth: 760, title: Text(orderTitle(context, order))),
      body: PageBody(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Insets.page, Insets.sm, Insets.page, Insets.xxl),
          children: [
            for (final line in order.lines) _LineTile(line: line, orderRef: orderRef),
            const SizedBox(height: Insets.md),
            _Totals(order: order),
            if (order.placedHere) ...[
              const SizedBox(height: Insets.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: context.palette.inkFaint),
                  const SizedBox(width: Insets.sm),
                  Expanded(child: Text(l10n.orderKeptLocally(order.id), style: Theme.of(context).textTheme.bodySmall)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line, required this.orderRef});

  final OrderLine line;
  final String orderRef;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Pressable(
        color: p.surface,
        ripple: true,
        scale: 0.98,
        onTap: () => context.push(Routes.product(line.productId, from: Routes.order(orderRef))),
        child: Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 64,
                child: ExcludeSemantics(
                  child: ProductImage(url: line.thumbnail, padding: Insets.sm, radius: Corners.input),
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: p.ink),
                    ),
                    Text(
                      l10n.orderQuantityPrice(line.quantity, formatPrice(context, line.price)),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.sm),
              Text(formatPrice(context, line.total), style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.order});

  final Order order;

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

    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(Corners.card)),
      child: Column(
        children: [
          row(l10n.subtotal, formatPrice(context, order.subtotal)),
          if (order.discount > 0) row(l10n.discount, formatPrice(context, -order.discount), valueColor: p.accent),
          const SizedBox(height: Insets.xs),
          row(l10n.total, formatPrice(context, order.total), style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
