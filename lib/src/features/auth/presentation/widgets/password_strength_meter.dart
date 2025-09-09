import 'package:flutter/material.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/design/palette.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/validation/validators.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final (filled, label, color) = switch (strength) {
      PasswordStrength.empty => (0, '', p.border),
      PasswordStrength.weak => (1, l10n.strengthWeak, p.danger),
      PasswordStrength.fair => (2, l10n.strengthFair, p.accent),
      PasswordStrength.good => (3, l10n.strengthGood, p.success),
      PasswordStrength.strong => (4, l10n.strengthStrong, p.success),
    };

    return Semantics(
      label: label,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: Motion.base,
                height: 4,
                decoration: BoxDecoration(
                  color: i < filled ? color : p.surfaceMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 3) const SizedBox(width: 4),
          ],
          SizedBox(
            width: 64,
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: strength == PasswordStrength.empty ? null : color),
            ),
          ),
        ],
      ),
    );
  }
}
