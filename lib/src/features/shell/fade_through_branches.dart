import 'package:flutter/material.dart';

import '../../core/widgets/motion.dart';

/// Holds the tab navigators like an IndexedStack, but switching tabs fades
/// the old one out and the new one in while it grows from 96%.
class FadeThroughBranches extends StatelessWidget {
  const FadeThroughBranches({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (i, navigator) in children.indexed)
          _Branch(active: i == currentIndex, still: still, child: navigator),
      ],
    );
  }
}

class _Branch extends StatefulWidget {
  const _Branch({required this.active, required this.still, required this.child});

  final bool active;
  final bool still;
  final Widget child;

  @override
  State<_Branch> createState() => _BranchState();
}

class _BranchState extends State<_Branch> {
  /// Faded out completely, so it can leave the screen until it's picked again.
  late bool _gone = !widget.active;

  @override
  void didUpdateWidget(_Branch old) {
    super.didUpdateWidget(old);
    if (widget.active && _gone) setState(() => _gone = false);
    if (!widget.active && widget.still) _gone = true;
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    // The outgoing tab leaves quickly; the incoming one takes a little longer.
    final duration = widget.still ? Duration.zero : Duration(milliseconds: active ? 280 : 140);
    return Offstage(
      // Like an IndexedStack: a hidden tab keeps its state but isn't painted
      // or hit-tested.
      offstage: _gone,
      child: IgnorePointer(
        ignoring: !active,
        child: ExcludeFocus(
          excluding: !active,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: duration,
            curve: Curves.easeOut,
            onEnd: () {
              if (!widget.active && mounted) setState(() => _gone = true);
            },
            child: AnimatedScale(
              scale: active ? 1 : 0.96,
              duration: duration,
              curve: Curves.easeOutCubic,
              // Hidden tabs keep their state but stop animating.
              child: TickerMode(enabled: active, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
