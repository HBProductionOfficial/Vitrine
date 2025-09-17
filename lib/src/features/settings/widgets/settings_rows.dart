import 'package:flutter/material.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/motion.dart';

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
            borderRadius: BorderRadius.circular(Corners.card),
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
class SettingsRow extends StatefulWidget {
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
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final tint = widget.color ?? p.ink;

    final Widget? end =
        widget.trailing ??
        (widget.onTap == null || widget.color != null
            ? null
            : AnimatedSlide(
                // The chevron leans in the direction you're about to go.
                offset: Offset(_down && !widget.external ? 0.25 : 0, 0),
                duration: Motion.fast,
                child: Icon(
                  widget.external ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
                  size: widget.external ? 18 : 24,
                  color: p.inkFaint,
                ),
              ));

    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (down) => setState(() => _down = down),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: Insets.sm),
          child: PressScale(
            down: _down,
            scale: 0.98,
            child: Row(
              children: [
                Icon(widget.icon, size: 22, color: widget.color ?? p.inkSoft),
                const SizedBox(width: Insets.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.label, style: theme.textTheme.bodyLarge?.copyWith(color: tint, height: 1.3)),
                      if (widget.hint != null) Text(widget.hint!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (widget.value != null) ...[
                  const SizedBox(width: Insets.sm),
                  AnimatedSwitcher(
                    duration: Motion.base,
                    child: Text(widget.value!, key: ValueKey(widget.value), style: theme.textTheme.bodyMedium),
                  ),
                ],
                if (end != null) ...[const SizedBox(width: Insets.xs), end],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One entry for [showOptionSheet].
class SheetOption<T> {
  const SheetOption({required this.value, required this.label, this.hint, this.badgeText, this.badgeIcon});

  final T value;
  final String label;
  final String? hint;
  final String? badgeText;
  final IconData? badgeIcon;
}

/// A short list to pick one from. The new choice lights up before the sheet
/// closes, so the change is visible rather than instant. Returns the chosen
/// option, or null if the sheet was dismissed.
Future<SheetOption<T>?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required T current,
  required List<SheetOption<T>> options,
}) {
  return showAppSheet<SheetOption<T>>(
    context,
    builder: (_) => _OptionSheet<T>(title: title, current: current, options: options),
  );
}

class _OptionSheet<T> extends StatefulWidget {
  const _OptionSheet({required this.title, required this.current, required this.options});

  final String title;
  final T current;
  final List<SheetOption<T>> options;

  @override
  State<_OptionSheet<T>> createState() => _OptionSheetState<T>();
}

class _OptionSheetState<T> extends State<_OptionSheet<T>> {
  late T _selected = widget.current;
  bool _closing = false;

  Future<void> _pick(SheetOption<T> option) async {
    if (_closing) return;
    setState(() {
      _selected = option.value;
      _closing = true;
    });
    if (!reduceMotion(context)) await Future<void>.delayed(const Duration(milliseconds: 260));
    if (mounted) Navigator.pop(context, option);
  }

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
            Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Insets.lg),
            for (final (i, option) in widget.options.indexed)
              FadeSlideIn(
                delay: FadeSlideIn.stagger(i),
                child: _OptionTile(option: option, selected: option.value == _selected, onTap: () => _pick(option)),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatefulWidget {
  const _OptionTile({required this.option, required this.selected, required this.onTap});

  final SheetOption<Object?> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final selected = widget.selected;
    final option = widget.option;
    final fg = selected ? p.onInk : p.ink;
    final faint = selected ? p.onInk.withValues(alpha: 0.75) : p.inkFaint;

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: PressScale(
        down: _down,
        scale: 0.97,
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.move,
          decoration: BoxDecoration(
            color: selected ? p.ink : p.surfaceMuted,
            borderRadius: BorderRadius.circular(Corners.button),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(Corners.button),
              onTap: widget.onTap,
              onHighlightChanged: (down) => setState(() => _down = down),
              child: Semantics(
                selected: selected,
                child: Padding(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: Motion.base,
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? p.onInk.withValues(alpha: 0.14) : p.surface,
                          shape: BoxShape.circle,
                        ),
                        child: option.badgeIcon != null
                            ? Icon(option.badgeIcon, size: 18, color: fg)
                            : Text(option.badgeText ?? '', style: theme.textTheme.labelSmall?.copyWith(color: fg)),
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: Motion.base,
                              style: theme.textTheme.titleSmall!.copyWith(color: fg),
                              child: Text(option.label),
                            ),
                            if (option.hint != null)
                              AnimatedDefaultTextStyle(
                                duration: Motion.base,
                                style: theme.textTheme.bodySmall!.copyWith(color: faint),
                                child: Text(option.hint!),
                              ),
                          ],
                        ),
                      ),
                      AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: Motion.slow,
                        curve: selected ? Curves.elasticOut : Motion.exit,
                        child: Icon(Icons.check_rounded, color: fg),
                      ),
                    ],
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
