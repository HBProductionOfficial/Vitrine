import 'package:flutter/material.dart';

import '../design/palette.dart';
import '../design/tokens.dart';
import 'motion.dart';

enum NoticeTone { error, info }

/// Inline message for form-level problems, shown above the submit button.
class Notice extends StatelessWidget {
  const Notice({super.key, required this.message, this.tone = NoticeTone.error, this.action});

  final String message;
  final NoticeTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isError = tone == NoticeTone.error;
    final fg = isError ? p.danger : p.inkSoft;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isError ? p.dangerSoft : p.surfaceMuted,
          borderRadius: BorderRadius.circular(Corners.input),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.info_outline_rounded, size: 20, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg)),
                  if (action != null) action!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a form shows its error. The space opens and closes smoothly instead
/// of pushing the button down in one jump; a null [message] closes it.
class NoticeSlot extends StatelessWidget {
  const NoticeSlot({super.key, this.message, this.gap = Insets.md});

  final String? message;

  /// Space above the notice while it's showing.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: reduceMotion(context) ? Duration.zero : Motion.base,
      curve: Motion.move,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: EdgeInsets.only(top: gap),
              child: FadeSlideIn(
                key: ValueKey(message),
                child: Notice(message: message!),
              ),
            ),
    );
  }
}
