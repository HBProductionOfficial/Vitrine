import 'package:flutter/material.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/tokens.dart';

/// A titled card of rows with hairlines between them. Used by Profile and
/// Settings so the two screens read as one set.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: Insets.xs, bottom: Insets.sm),
              child: Text(title!, style: Theme.of(context).textTheme.titleSmall),
            ),
          Material(
            color: p.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.card),
              side: BorderSide(color: p.border),
            ),
            child: Column(
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) const Divider(indent: Insets.lg, endIndent: Insets.lg),
                  child,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon, label, optional hint and value. Shows a chevron when it goes
/// somewhere, or an outward arrow when it leaves the app.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.value,
    this.trailing,
    this.onTap,
    this.external = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool external;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final tint = color ?? p.ink;

    final Widget? end =
        trailing ??
        (onTap == null || color != null
            ? null
            : Icon(
                external ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
                size: external ? 18 : 24,
                color: p.inkFaint,
              ));

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: Insets.sm),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color ?? p.inkSoft),
              const SizedBox(width: Insets.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: tint, height: 1.3)),
                    if (hint != null) Text(hint!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (value != null) ...[const SizedBox(width: Insets.sm), Text(value!, style: theme.textTheme.bodyMedium)],
              if (end != null) ...[const SizedBox(width: Insets.xs), end],
            ],
          ),
        ),
      ),
    );
  }
}

/// One choice in a picker sheet: a round badge (letters or an icon), a label
/// with an optional hint, and a check on the current one.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.hint,
    this.badgeText,
    this.badgeIcon,
  });

  final String label;
  final String? hint;
  final String? badgeText;
  final IconData? badgeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final badgeColor = selected ? p.onInk : p.inkSoft;

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Material(
        color: selected ? p.surfaceMuted : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.button),
          side: BorderSide(color: selected ? p.ink : p.border, width: selected ? 1.4 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Insets.md),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: selected ? p.ink : p.surfaceMuted, shape: BoxShape.circle),
                  child: badgeIcon != null
                      ? Icon(badgeIcon, size: 18, color: badgeColor)
                      : Text(badgeText ?? '', style: theme.textTheme.labelSmall?.copyWith(color: badgeColor)),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.titleSmall),
                      if (hint != null) Text(hint!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_rounded, color: p.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet body for a short list of [OptionTile]s under a title.
class OptionSheet extends StatelessWidget {
  const OptionSheet({super.key, required this.title, required this.options});

  final String title;
  final List<Widget> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Insets.xl, 0, Insets.xl, Insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Insets.lg),
            ...options,
          ],
        ),
      ),
    );
  }
}
