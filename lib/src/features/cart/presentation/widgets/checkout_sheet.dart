import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/design/palette.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/format.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/notice.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../cart_controller.dart';

class CheckoutSheet extends ConsumerStatefulWidget {
  const CheckoutSheet({super.key});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  bool _placing = false;
  bool _failed = false;
  int? _orderId;

  Future<void> _place() async {
    setState(() {
      _placing = true;
      _failed = false;
    });
    try {
      final id = await ref.read(cartProvider.notifier).checkout();
      if (mounted) setState(() => _orderId = id);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The sheet resizes and cross-fades from the review to the confirmation.
    return AnimatedSize(
      duration: Motion.slow,
      curve: Motion.move,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: Motion.base,
        child: _orderId == null
            ? KeyedSubtree(key: const ValueKey('review'), child: _review(context))
            : _success(context),
      ),
    );
  }

  Widget _success(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = context.palette;
    return Padding(
      key: const ValueKey('done'),
      padding: const EdgeInsets.fromLTRB(Insets.xl, 0, Insets.xl, Insets.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, t, child) => Transform.scale(scale: t, child: child),
            child: Icon(Icons.check_circle_rounded, size: 48, color: p.success),
          ),
          const SizedBox(height: Insets.md),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Text(l10n.orderPlacedTitle, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: Insets.sm),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(l10n.orderPlacedBody('#$_orderId'), style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: Insets.xl),
          PrimaryButton(
            label: l10n.keepShopping,
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.pop(context);
              router.go(Routes.shop);
            },
          ),
          const SizedBox(height: Insets.sm),
          SecondaryButton(
            label: l10n.viewOrders,
            icon: Icons.receipt_long_outlined,
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.pop(context);
              router.go(Routes.orders);
            },
          ),
        ],
      ),
    );
  }

  Widget _review(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = context.palette;

    final cart = ref.watch(cartProvider);
    final user = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.xl, 0, Insets.xl, Insets.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.checkoutTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Insets.lg),
          Text(l10n.deliverTo, style: theme.textTheme.labelMedium),
          const SizedBox(height: Insets.xs),
          user.when(
            data: (u) =>
                Text([u.fullName, ?u.address].join('\n'), style: theme.textTheme.bodyMedium?.copyWith(color: p.ink)),
            loading: () => const Shimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [SkeletonBox(width: 140), SizedBox(height: 6), SkeletonBox(width: 220)],
              ),
            ),
            error: (_, _) => Text(l10n.profileLoadFailed, style: theme.textTheme.bodyMedium),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Insets.lg),
            child: Divider(),
          ),
          Row(
            children: [
              Expanded(child: Text(l10n.itemsCount(cart.count), style: theme.textTheme.bodyMedium)),
              Text(formatPrice(context, cart.total), style: theme.textTheme.titleMedium),
            ],
          ),
          NoticeSlot(message: _failed ? l10n.orderFailed : null, gap: Insets.lg),
          const SizedBox(height: Insets.xl),
          PrimaryButton(label: l10n.placeOrder, loading: _placing, onPressed: cart.isEmpty ? null : _place),
        ],
      ),
    );
  }
}
