import 'package:flutter/material.dart';

import '../design/palette.dart';
import '../design/tokens.dart';
import 'motion.dart';

/// Full-width ink button. While [loading] it keeps its size and shows a
/// spinner, so the layout below doesn't jump.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.accent = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  /// Terracotta instead of ink. Reserved for "Add to cart".
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = accent
        ? FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: Palette.readableOn(p.accent))
        : null;
    final content = loading
        ? SizedBox.square(
            key: const ValueKey('loading'),
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: accent ? Palette.readableOn(p.accent) : p.onInk),
          )
        : _Label(key: ValueKey('$icon$label'), label: label, icon: icon);
    return SizedBox(
      width: double.infinity,
      child: ScaleOnPress(
        builder: (states) => FilledButton(
          statesController: states,
          style: style,
          onPressed: loading ? null : onPressed,
          child: _Swap(child: content),
        ),
      ),
    );
  }
}

/// Grey tonal button for the second choice on a screen.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.icon, this.leading});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Used instead of [icon] when one glyph isn't enough.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ScaleOnPress(
        builder: (states) => OutlinedButton(
          statesController: states,
          onPressed: onPressed,
          child: _Label(label: label, icon: icon, leading: leading),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({super.key, required this.label, this.icon, this.leading});

  final String label;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final start = leading ?? (icon == null ? null : Icon(icon, size: 20));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (start != null) ...[start, const SizedBox(width: 8)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/// Cross-fades the button content when the label, icon or spinner changes.
class _Swap extends StatelessWidget {
  const _Swap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: reduceMotion(context) ? Duration.zero : Motion.base,
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(animation), child: child),
      ),
      child: child,
    );
  }
}
