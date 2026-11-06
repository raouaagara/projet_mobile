import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';

/// Workify's mark: a W whose last stroke leaves as an arrow going up.
///
/// Same drawing as `mobile/branding/workify-logo.svg` and the Android launcher icon.
/// Pass one [color] for a single-color version (e.g. white on green).
class WorkifyLogo extends StatelessWidget {
  const WorkifyLogo({super.key, this.size = 64, this.color, this.arrowColor, this.progress = 1});

  final double size;
  final Color? color;
  final Color? arrowColor;

  /// How much of the mark is drawn, from 0 to 1, in the order a pen draws it:
  /// the W from its top left, on up the arrow, then the arrow head.
  final double progress;

  @override
  Widget build(BuildContext context) => Semantics(
        label: Brand.name,
        image: true,
        child: CustomPaint(
          size: Size.square(size),
          painter: WorkifyMarkPainter(
            color: color ?? Brand.darkGreen,
            arrowColor: arrowColor ?? color ?? Brand.green,
            progress: progress,
          ),
        ),
      );
}

/// Paints the mark centered in a square. Also draws the launcher PNGs (tool/render_launcher_icons.dart).
class WorkifyMarkPainter extends CustomPainter {
  const WorkifyMarkPainter({required this.color, required this.arrowColor, this.progress = 1});

  final Color color;
  final Color arrowColor;
  final double progress;

  // Drawn in a 340×340 box centered on (0, 0), like the SVG, in the pen's order.
  static const _box = 340.0;
  static final _w = Path()
    ..moveTo(-146, -29)
    ..lineTo(-86, 93)
    ..lineTo(-27, 1)
    ..lineTo(33, 93);
  static final _shaft = Path()
    ..moveTo(33, 93)
    ..lineTo(130, -86);
  static final _head = Path()
    ..moveTo(72, -75)
    ..lineTo(136, -97)
    ..lineTo(151, -37);
  static final _lengths = [for (final path in [_w, _shaft, _head]) path.computeMetrics().first.length];

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(size.shortestSide / _box);

    Paint stroke(Color c, double width) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The pen moves at the same speed along the W, the arrow and its head.
    var ink = progress.clamp(0.0, 1.0) * _lengths.reduce((a, b) => a + b);
    Path drawn(Path path, double length) {
      final part = ink >= length ? path : ink > 0 ? path.computeMetrics().first.extractPath(0, ink) : Path();
      ink -= length;
      return part;
    }

    final w = drawn(_w, _lengths[0]);
    final shaft = drawn(_shaft, _lengths[1]);
    final head = drawn(_head, _lengths[2]);
    // The arrow leaves the bottom of the W: the W is painted over its start.
    canvas
      ..drawPath(shaft, stroke(arrowColor, 40))
      ..drawPath(head, stroke(arrowColor, 34))
      ..drawPath(w, stroke(color, 48))
      ..restore();
  }

  @override
  bool shouldRepaint(WorkifyMarkPainter old) =>
      old.color != color || old.arrowColor != arrowColor || old.progress != progress;
}
