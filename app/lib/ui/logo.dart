import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The Bolzplatz AG logo: "BOLZ" with a ball as the O over a yellow "PLATZ",
/// and the AG as a slanted company stamp. [height] is the height of the
/// whole logo; everything scales with it.
class BolzplatzLogo extends StatelessWidget {
  const BolzplatzLogo({this.height = 270, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    const baseHeight = 270.0;
    const letter = 110.0;
    TextStyle style(Color color) => TextStyle(
      fontFamily: Tokens.headlineFont,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation.weight(700)],
      fontSize: letter,
      height: 1,
      letterSpacing: -2,
      color: color,
    );
    return Semantics(
      label: 'Bolzplatz AG',
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              height: baseHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('B', style: style(Tokens.text)),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 80,
                        height: 80,
                        child: CustomPaint(painter: _BallPainter()),
                      ),
                      const SizedBox(width: 8),
                      Text('LZ', style: style(Tokens.text)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('PLATZ', style: style(Tokens.yellow)),
                      const SizedBox(width: 20),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Transform.rotate(
                          angle: -9 * math.pi / 180,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Tokens.orange,
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'AG',
                              style: style(
                                Tokens.orange,
                              ).copyWith(fontSize: 38, letterSpacing: 0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A football: cream disc, dark pentagon in the middle, five seams.
class _BallPainter extends CustomPainter {
  const _BallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, r, Paint()..color = Tokens.cream);
    final dark = Paint()..color = Tokens.ground;
    final seam = Paint()
      ..color = Tokens.ground
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    final pentagon = Path();
    for (var i = 0; i < 5; i++) {
      final a = (i * 72 - 90) * math.pi / 180;
      final inner = c + Offset(math.cos(a), math.sin(a)) * (r * 0.42);
      final outer = c + Offset(math.cos(a), math.sin(a)) * (r * 0.95);
      if (i == 0) {
        pentagon.moveTo(inner.dx, inner.dy);
      } else {
        pentagon.lineTo(inner.dx, inner.dy);
      }
      canvas.drawLine(inner, outer, seam);
    }
    pentagon.close();
    canvas.drawPath(pentagon, dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
