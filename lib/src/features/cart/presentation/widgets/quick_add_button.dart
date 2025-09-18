import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/design/palette.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../shop/domain/product.dart';
import '../cart_controller.dart';

/// Round add-to-cart button for product cards. Once the product is in the
/// cart it fills in and shows how many; each tap adds one more.
class QuickAddButton extends ConsumerWidget {
  const QuickAddButton({super.key, required this.product});

  final Product product;

  void _add(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    if (!ref.read(cartProvider.notifier).add(product)) return;
    showSnack(
      context,
      l10n.addedToCart,
      action: SnackBarAction(label: l10n.viewCart, onPressed: () => router.go(Routes.cart)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final inCart = ref.watch(cartProvider.select((c) => c.quantityOf(product.id)));
    final canAdd = inCart < ref.read(cartProvider.notifier).limitFor(product);
    final filled = inCart > 0;

    return Tooltip(
      message: filled ? l10n.inCartCount(inCart) : l10n.addToCart,
      child: Pressable(
        onTap: canAdd ? () => _add(context, ref) : null,
        semanticLabel: filled ? '${l10n.addToCart}, ${l10n.inCartCount(inCart)}' : l10n.addToCart,
        borderRadius: BorderRadius.circular(22),
        scale: 0.85,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: BumpOnChange(
              value: inCart == 0 ? null : inCart,
              child: AnimatedContainer(
                duration: Motion.base,
                curve: Motion.move,
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: filled ? p.ink : p.surface, shape: BoxShape.circle),
                child: AnimatedSwitcher(
                  duration: Motion.base,
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: filled
                      ? Text(
                          '$inCart',
                          key: ValueKey(inCart),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: p.onInk),
                        )
                      : Icon(
                          Icons.add_rounded,
                          key: const ValueKey('add'),
                          size: 22,
                          color: canAdd ? p.ink : p.inkFaint,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
