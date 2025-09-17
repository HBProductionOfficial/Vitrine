import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/motion.dart';
import '../../shop/domain/product.dart';
import 'saved_controller.dart';

/// Heart toggle. Saving pops the heart; un-saving just swaps it back.
class SaveButton extends ConsumerWidget {
  const SaveButton({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final saved = ref.watch(savedProvider.select((list) => list.any((s) => s.id == product.id)));
    return IconButton(
      tooltip: saved ? l10n.unsaveProduct : l10n.saveProduct,
      isSelected: saved,
      onPressed: () => ref.read(savedProvider.notifier).toggle(product),
      icon: BumpOnChange(
        // Only bump on the way in.
        value: saved ? true : null,
        amount: 0.4,
        child: AnimatedSwitcher(
          duration: reduceMotion(context) ? Duration.zero : Motion.base,
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Icon(
            saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(saved),
            color: saved ? p.ink : p.inkSoft,
          ),
        ),
      ),
    );
  }
}
