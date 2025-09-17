import 'package:flutter/material.dart';

import '../design/tokens.dart';
import 'motion.dart';

/// Tappable area that shrinks slightly while pressed. Built on InkWell so it
/// stays reachable with a keyboard and gets a focus highlight.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = const BorderRadius.all(Radius.circular(Corners.card)),
    this.semanticLabel,
    this.scale = 0.97,
    this.ripple = false,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final double scale;

  /// Ink ripple on top of the shrink, for rows on a plain surface. Product
  /// cards skip it because the photo already shows the press.
  final bool ripple;

  /// Background that shrinks along with the content.
  final Color? color;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: PressScale(
        down: _down,
        scale: widget.scale,
        child: Material(
          type: widget.color == null ? MaterialType.transparency : MaterialType.canvas,
          color: widget.color,
          borderRadius: widget.borderRadius,
          clipBehavior: widget.color == null ? Clip.none : Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onHighlightChanged: (value) => setState(() => _down = value),
            borderRadius: widget.borderRadius,
            splashFactory: widget.ripple ? null : NoSplash.splashFactory,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
