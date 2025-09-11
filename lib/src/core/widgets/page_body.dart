import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Side padding that centres content at most [maxWidth] wide. For scroll
/// views that should still scroll from anywhere in the window.
double pageGutter(double width, {double maxWidth = Breakpoints.contentMaxWidth}) {
  return math.max(Insets.page, (width - maxWidth) / 2);
}

/// Caps content width on tablets and the web so lines and grids don't
/// stretch across the whole window.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = Breakpoints.contentMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
