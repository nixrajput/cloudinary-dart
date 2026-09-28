import 'package:flutter/widgets.dart';

/// The package logo, drawn on the same 32 x 32 grid as `assets/logo.svg` so
/// the example needs no SVG dependency.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'cloudinary logo',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _LogoPainter()),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  static const _tile = Color(0xFF141118);
  static const _violet = Color(0xFF9B8CFF);
  static const _amber = Color(0xFFF0A868);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32);
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, 32, 32, const Radius.circular(7)),
      Paint()..color = _tile,
    );
    final cloud = Paint()..color = _violet;
    canvas
      ..drawCircle(const Offset(16, 12.8), 6, cloud)
      ..drawCircle(const Offset(10.5, 16.3), 4.5, cloud)
      ..drawCircle(const Offset(21.5, 16.3), 4.5, cloud)
      ..drawRect(const Rect.fromLTWH(10.5, 16.3, 11, 4.5), cloud);
    final arrow = Path()
      ..moveTo(16, 26)
      ..lineTo(16, 14.8)
      ..moveTo(12.2, 18.6)
      ..lineTo(16, 14.8)
      ..lineTo(19.8, 18.6);
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Cut out of the cloud in the tile colour first, as the SVG does.
    canvas
      ..drawPath(arrow, stroke(_tile, 5.4))
      ..drawPath(arrow, stroke(_amber, 2.6));
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
