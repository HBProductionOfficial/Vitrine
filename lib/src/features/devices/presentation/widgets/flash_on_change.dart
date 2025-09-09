import 'package:flutter/material.dart';

import '../../../../core/design/palette.dart';

/// Briefly tints its background whenever [value] changes, so a live reading
/// that just updated catches the eye and then settles back.
class FlashOnChange extends StatefulWidget {
  const FlashOnChange({super.key, required this.value, required this.child, this.borderRadius});

  final Object value;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<FlashOnChange> createState() => _FlashOnChangeState();
}

class _FlashOnChangeState extends State<FlashOnChange> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    value: 1,
  );

  @override
  void didUpdateWidget(FlashOnChange old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Hold the highlight for a moment, then fade it out.
        final t = Curves.easeIn.transform(((_controller.value - 0.35) / 0.65).clamp(0.0, 1.0));
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(p.accentSoft, p.surfaceMuted, t),
            borderRadius: widget.borderRadius,
          ),
          child: child,
        );
      },
    );
  }
}
