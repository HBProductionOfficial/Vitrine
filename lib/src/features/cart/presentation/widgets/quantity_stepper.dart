import 'package:flutter/material.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/design/palette.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/pressable.dart';

/// Minus / count / plus. At a quantity of one the minus turns into a bin,
/// because going lower means removing the line.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.max,
    required this.onChanged,
    required this.onRemove,
  });

  final int quantity;
  final int max;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final last = quantity == 1;
    return Container(
      decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: BorderRadius.circular(Corners.button)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            tooltip: last ? l10n.removeFromCart : l10n.decreaseQuantity,
            onPressed: last ? onRemove : () => onChanged(quantity - 1),
            icon: AnimatedSwitcher(
              duration: Motion.base,
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween(begin: 0.6, end: 1.0).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                last ? Icons.delete_outline_rounded : Icons.remove_rounded,
                key: ValueKey(last),
                size: 20,
                color: last ? p.danger : null,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: RollingText('$quantity', style: Theme.of(context).textTheme.titleSmall, alignment: Alignment.center),
          ),
          _StepButton(
            tooltip: l10n.increaseQuantity,
            onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.tooltip, required this.onPressed, required this.icon});

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onPressed,
        semanticLabel: tooltip,
        ripple: true,
        scale: 0.85,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox.square(
          dimension: 44,
          child: IconTheme.merge(
            data: IconThemeData(color: onPressed == null ? p.inkFaint : p.ink),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}
