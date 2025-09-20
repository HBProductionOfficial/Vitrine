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
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../shop/presentation/widgets/product_image.dart';
import '../domain/order.dart';
import 'orders_controller.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final placed = ref.watch(placedOrdersProvider);
    final history = ref.watch(orderHistoryProvider);
    final nothing = placed.isEmpty && (history.value?.isEmpty ?? false);

    return Scaffold(
      appBar: PageAppBar(maxWidth: 760, title: Text(l10n.ordersTitle)),
      body: nothing
          ? MessageView(icon: Icons.receipt_long_outlined, title: l10n.ordersEmptyTitle, message: l10n.ordersEmptyBody)
          : PageBody(
              maxWidth: 760,
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(orderHistoryProvider.future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(Insets.page, Insets.sm, Insets.page, Insets.xxl),
                  children: [
                    if (placed.isNotEmpty) ...[
                      _SectionTitle(l10n.ordersPlacedHere),
                      for (final (i, order) in placed.indexed)
                        FadeSlideIn(
                          delay: FadeSlideIn.stagger(i),
                          child: OrderCard(order: order),
                        ),
                      const SizedBox(height: Insets.lg),
                    ],
                    _SectionTitle(l10n.ordersEarlier, note: l10n.ordersEarlierNote),
                    ...history.when(
                      data: (orders) => orders.isEmpty
                          ? [Text(l10n.ordersNoneEarlier, style: Theme.of(context).textTheme.bodyMedium)]
                          : [
                              for (final (i, order) in orders.indexed)
                                FadeSlideIn(
                                  delay: FadeSlideIn.stagger(i + placed.length),
                                  child: OrderCard(order: order),
                                ),
                            ],
                      loading: () => const [_OrderSkeleton(), _OrderSkeleton()],
                      error: (e, _) => [
                        SizedBox(
                          height: 260,
                          child: ErrorView(
                            message: describeError(e, l10n),
                            onRetry: () => ref.invalidate(orderHistoryProvider),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.xs, Insets.sm, Insets.xs, Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (note != null) Text(note!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Date and time for orders placed here, DummyJSON's number for the rest.
String orderTitle(BuildContext context, Order order) {
  final l10n = AppLocalizations.of(context);
  if (!order.placedHere) return l10n.orderNumber(order.id);
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).add_Hm().format(order.placedAt!.toLocal());
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  static const _thumbs = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final theme = Theme.of(context);
    final extra = order.lines.length - _thumbs;

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Pressable(
        color: p.surface,
        ripple: true,
        scale: 0.98,
        onTap: () => context.push(Routes.order(order.ref)),
        child: Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(orderTitle(context, order), style: theme.textTheme.titleSmall)),
                  Text(formatPrice(context, order.total), style: theme.textTheme.titleSmall),
                  const SizedBox(width: Insets.xs),
                  Icon(Icons.chevron_right_rounded, color: p.inkFaint),
                ],
              ),
              Text(l10n.itemsCount(order.quantity), style: theme.textTheme.bodySmall),
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  for (final line in order.lines.take(_thumbs))
                    Padding(
                      padding: const EdgeInsets.only(right: Insets.sm),
                      child: SizedBox.square(
                        dimension: 48,
                        child: ExcludeSemantics(child: ProductImage(url: line.thumbnail, padding: 4, radius: 10)),
                      ),
                    ),
                  if (extra > 0) Text('+$extra', style: theme.textTheme.labelMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSkeleton extends StatelessWidget {
  const _OrderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Shimmer(
        child: Container(
          padding: const EdgeInsets.all(Insets.lg),
          decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(Corners.card)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 140),
              SizedBox(height: Insets.sm),
              SkeletonBox(width: 70),
              SizedBox(height: Insets.md),
              Row(
                children: [
                  SkeletonBox(width: 48, height: 48, radius: 10),
                  SizedBox(width: Insets.sm),
                  SkeletonBox(width: 48, height: 48, radius: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
