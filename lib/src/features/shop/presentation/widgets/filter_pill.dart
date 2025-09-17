import 'package:flutter/material.dart';

import '../../../../core/design/palette.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/widgets/motion.dart';

/// A category choice. The selected one fills with ink; switching slides the
/// colour across instead of snapping.
class FilterPill extends StatefulWidget {
  const FilterPill({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<FilterPill> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = widget.selected;
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        down: _down,
        scale: 0.94,
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.move,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? p.ink : p.surface,
            borderRadius: BorderRadius.circular(Corners.input),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (down) => setState(() => _down = down),
              borderRadius: BorderRadius.circular(Corners.input),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  widthFactor: 1,
                  child: AnimatedDefaultTextStyle(
                    duration: Motion.base,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(color: selected ? p.onInk : p.ink),
                    child: Text(widget.label),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
