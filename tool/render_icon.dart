// Draws the launcher icon with the same painter as the in-app mark, so the
// two can't drift apart. To regenerate:
//
//   flutter test tool/render_icon.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrine/src/core/design/palette.dart';
import 'package:vitrine/src/core/widgets/vitrine_mark.dart';

const _size = 1024.0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render launcher icons', () async {
    // iOS, web and old Android show this as is, cropped by the system mask.
    await _write('assets/icon/icon.png', background: Palette.light.ink, scale: 0.9);
    // Android's adaptive icon: only the mark. flutter_launcher_icons insets
    // it by 16%, which keeps it inside the safe zone of any launcher shape.
    await _write('assets/icon/foreground.png', scale: 1);
  });
}

Future<void> _write(String path, {Color? background, required double scale}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (background != null) canvas.drawRect(const Rect.fromLTWH(0, 0, _size, _size), Paint()..color = background);

  final box = _size * scale;
  canvas.translate((_size - box) / 2, (_size - box) / 2);
  VitrineMarkPainter(background: Colors.transparent, stroke: Palette.light.background).paint(canvas, Size.square(box));

  final image = await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).create(recursive: true);
  await File(path).writeAsBytes(png!.buffer.asUint8List());
}
