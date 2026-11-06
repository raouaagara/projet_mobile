// Draws the Android 7 launcher icons (mipmap-*/ic_launcher.png) with the app's own logo painter.
// Android 8+ uses the adaptive icon in android/app/src/main/res/drawable instead.
//
//   flutter test tool/render_launcher_icons.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:catchopp_mobile/core/theme/brand.dart';
import 'package:catchopp_mobile/shared/widgets/workify_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};

Future<List<int>> _icon(int size) async {
  final recorder = ui.PictureRecorder();
  // Designed on a 192 px canvas: white disc with a light green ring, the mark inside.
  final canvas = Canvas(recorder)..scale(size / 192);
  const center = Offset(96, 96);
  canvas
    ..drawCircle(center, 88, Paint()..color = Colors.white)
    ..drawCircle(center, 88, Paint()
      ..color = const Color(0xFFDDEBD3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3)
    ..translate(96 - 60, 96 - 60);
  const WorkifyMarkPainter(color: Brand.darkGreen, arrowColor: Brand.green).paint(canvas, const Size.square(120));
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

void main() {
  test('render the launcher icons', () async {
    for (final MapEntry(key: density, value: size) in _sizes.entries) {
      File('android/app/src/main/res/mipmap-$density/ic_launcher.png').writeAsBytesSync(await _icon(size));
    }
  });
}
