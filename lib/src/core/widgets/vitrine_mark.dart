import 'package:flutter/material.dart';

import '../design/palette.dart';

/// The app mark: a "V" drawn as two strokes inside a rounded square, like
/// the corner of a shop window frame.
class VitrineMark extends StatelessWidget {
  const VitrineMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Vitrine',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: VitrineMarkPainter(background: p.ink, stroke: p.background),
      ),
    );
  }
}

class VitrineMarkPainter extends CustomPainter {
  const VitrineMarkPainter({required this.background, required this.stroke});

  final Color background;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.26));
    canvas.drawRRect(rect, Paint()..color = background);

    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.105
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(s * 0.29, s * 0.3)
      ..lineTo(s * 0.5, s * 0.71)
      ..lineTo(s * 0.71, s * 0.3);
    canvas.drawPath(path, paint);

    // A short sill under the V turns the letter into a window frame.
    canvas.drawLine(Offset(s * 0.36, s * 0.83), Offset(s * 0.64, s * 0.83), paint..strokeWidth = s * 0.05);
  }

  @override
  bool shouldRepaint(VitrineMarkPainter old) => old.background != background || old.stroke != stroke;
}
