import 'package:flutter/material.dart';

import 'tokens.dart';

/// A new page slides in from the right and fades up while the page under it
/// drifts left and sinks back a little, so going deeper feels like moving
/// forward through a stack.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInCubic);
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1, curve: Curves.easeIn),
    );
    final behind = CurvedAnimation(parent: secondaryAnimation, curve: Motion.move);

    return SlideTransition(
      position: Tween(begin: Offset.zero, end: const Offset(-0.08, 0)).animate(behind),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.96).animate(behind),
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.14, 0), end: Offset.zero).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}
