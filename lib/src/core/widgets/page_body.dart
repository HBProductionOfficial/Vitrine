import 'package:flutter/material.dart';

import '../design/tokens.dart';

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
