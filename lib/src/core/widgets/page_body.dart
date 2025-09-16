import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Side padding that centres content at most [maxWidth] wide. For scroll
/// views that should still scroll from anywhere in the window.
double pageGutter(double width, {double maxWidth = Breakpoints.contentMaxWidth}) {
  return math.max(Insets.page, (width - maxWidth) / 2);
}

/// An app bar lined up with the centred content below it: the title, or the
/// back arrow, starts where the content starts and the last action ends
/// where it ends. [maxWidth] is the width of that content plus its padding.
class PageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PageAppBar({super.key, this.title, this.actions = const [], this.maxWidth = Breakpoints.contentMaxWidth});

  final Widget? title;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final edge = math.max(0.0, (constraints.maxWidth - maxWidth) / 2) + Insets.page;
        // Icon buttons keep 12 px of padding around the icon.
        final inset = math.max(0.0, edge - 12);
        return AppBar(
          titleSpacing: canPop ? null : edge,
          leadingWidth: canPop ? inset + 48 : null,
          leading: canPop
              ? Padding(
                  padding: EdgeInsets.only(left: inset),
                  child: const BackButton(),
                )
              : null,
          automaticallyImplyLeading: false,
          title: title,
          actions: [
            ...actions,
            SizedBox(width: inset),
          ],
        );
      },
    );
  }
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
      // Only as tall as the child, so it also works inside bottom bars.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
