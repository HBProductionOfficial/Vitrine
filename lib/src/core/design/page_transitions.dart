import 'package:flutter/material.dart';

import 'tokens.dart';

/// New pages fade in while sliding a short distance from the right, so the
/// direction of travel is clear without the full-width Android zoom.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(parent: animation, curve: Motion.enter, reverseCurve: Motion.exit);
    final slide = Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(enter);
    final behind = Tween(
      begin: Offset.zero,
      end: const Offset(-0.03, 0),
    ).animate(CurvedAnimation(parent: secondaryAnimation, curve: Motion.move));
    return SlideTransition(
      position: behind,
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(position: slide, child: child),
      ),
    );
  }
}
