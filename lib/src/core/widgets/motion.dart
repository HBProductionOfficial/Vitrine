import 'dart:async';

import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// True when the phone asks for less motion; animations then jump to the end.
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Shrinks a Material button while it's held and springs back on release.
/// Follows the button's own pressed state, so a press that turns into a
/// scroll lets go as well.
class ScaleOnPress extends StatefulWidget {
  const ScaleOnPress({super.key, required this.builder, this.scale = 0.96});

  final Widget Function(WidgetStatesController states) builder;
  final double scale;

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress> {
  final _states = WidgetStatesController();
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(() {
      final down = _states.value.contains(WidgetState.pressed);
      if (down != _down) setState(() => _down = down);
    });
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressScale(down: _down, scale: widget.scale, child: widget.builder(_states));
  }
}

/// The scale animation itself: quick to press in, a small overshoot on release.
class PressScale extends StatelessWidget {
  const PressScale({super.key, required this.down, required this.child, this.scale = 0.96});

  final bool down;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return AnimatedScale(
      scale: down && !still ? scale : 1,
      duration: down ? Motion.fast : Motion.slow,
      curve: down ? Curves.easeOut : Curves.easeOutBack,
      child: child,
    );
  }
}

/// Gives its child a short bounce whenever [value] changes to something
/// other than null, e.g. the cart badge when something is added.
class BumpOnChange extends StatefulWidget {
  const BumpOnChange({super.key, required this.value, required this.child, this.amount = 0.3});

  final Object? value;
  final double amount;
  final Widget child;

  @override
  State<BumpOnChange> createState() => _BumpOnChangeState();
}

class _BumpOnChangeState extends State<BumpOnChange> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1 + widget.amount).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1 + widget.amount, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(BumpOnChange old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != null && !reduceMotion(context)) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}

/// Fades its child in while it rises a few pixels. [delay] staggers items in
/// a list so they arrive one after another instead of all at once.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.enabled = true});

  final Widget child;
  final Duration delay;

  /// False shows the child straight away, e.g. for an item already seen.
  final bool enabled;

  /// Delay for the [index]th item of a list, capped so long lists don't wait.
  static Duration stagger(int index) => Duration(milliseconds: 40 * index.clamp(0, 8));

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: Motion.slow, value: widget.enabled ? 0 : 1);
  late final _curve = CurvedAnimation(parent: _controller, curve: Motion.enter);
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value == 1 || _controller.isAnimating || _timer != null) return;
    if (reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Text that rolls to its new value: the new text rises in as the old one
/// fades, the way a counter ticks over. For prices, totals and quantities.
class RollingText extends StatelessWidget {
  const RollingText(this.text, {super.key, this.style, this.alignment = Alignment.centerRight});

  final String text;
  final TextStyle? style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: reduceMotion(context) ? Duration.zero : Motion.base,
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      layoutBuilder: (current, previous) => Stack(alignment: alignment, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(text);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: Offset(0, incoming ? 0.6 : -0.6), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(text, key: ValueKey(text), style: style),
    );
  }
}
