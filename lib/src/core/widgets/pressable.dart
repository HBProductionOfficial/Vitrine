import 'package:flutter/material.dart';

import '../design/tokens.dart';

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
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final String? semanticLabel;

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
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: Motion.fast,
        curve: Motion.enter,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onHighlightChanged: (value) => setState(() => _down = value),
            borderRadius: widget.borderRadius,
            splashFactory: NoSplash.splashFactory,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
