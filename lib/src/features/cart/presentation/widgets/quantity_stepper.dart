import 'package:flutter/material.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/design/palette.dart';
import '../../../../core/design/tokens.dart';

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
    const size = BoxConstraints.tightFor(width: 44, height: 44);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(Corners.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: size,
            padding: EdgeInsets.zero,
            tooltip: quantity == 1 ? l10n.removeFromCart : l10n.decreaseQuantity,
            onPressed: quantity == 1 ? onRemove : () => onChanged(quantity - 1),
            icon: Icon(quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded, size: 20),
          ),
          SizedBox(
            width: 28,
            child: Text('$quantity', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
          ),
          IconButton(
            constraints: size,
            padding: EdgeInsets.zero,
            tooltip: l10n.increaseQuantity,
            onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
