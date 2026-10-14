import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../theme/tokens.dart';

/// Colours of the looks options. The index is the value in
/// [TrainerAppearance]; the counts match `career.appearance_options` in the
/// rules file.
abstract final class TrainerLooks {
  static const List<Color> skin = [
    Color(0xFFF3D2B3),
    Color(0xFFE3B38A),
    Color(0xFFC68A5A),
    Color(0xFF93603B),
    Color(0xFF5D3D28),
  ];
  static const List<Color> hair = [
    Color(0xFF1C1A1A),
    Color(0xFF5A3A26),
    Color(0xFFD9B35A),
    Color(0xFFB4501E),
    Color(0xFFBDBDBD),
  ];
  /// Outfit colours: the game colours plus navy, black and white.
  static const List<Color> outfit = [
    Color(0xFF2E8B57),
    Color(0xFFFFC400),
    Color(0xFFFF7A1A),
    Color(0xFF1F2A5A),
    Color(0xFF1B1B1B),
    Color(0xFFF4F1E8),
  ];
}

/// The trainer as a comic portrait: thick ink outlines, a big head, big eyes
/// and a wide grin.
class TrainerAvatar extends StatelessWidget {
  const TrainerAvatar({required this.appearance, this.size = 160, super.key});

  final TrainerAppearance appearance;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AvatarPainter(appearance)),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.a);

  final TrainerAppearance a;

  static const Color _ink = Color(0xFF14100A);
  static const double _line = 2.2;

  late final Paint _outline = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = _line
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  late final Paint _thin = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  /// Fills a shape and draws its ink outline.
  void _shape(Canvas canvas, Path path, Color color) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, _outline);
  }

  Path _oval(double cx, double cy, double w, double h) =>
      Path()
        ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));

  Path _rrect(double l, double t, double w, double h, double r) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r)),
    );

  Paint _fill(Color c) => Paint()..color = c;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final woman = a.gender == 1;
    final skin = TrainerLooks.skin[a.skin];
    final skinDeep = Color.lerp(skin, const Color(0xFF000000), 0.16)!;
    final hair = TrainerLooks.hair[a.hairColour];
    final hairDeep = Color.lerp(hair, const Color(0xFF000000), 0.2)!;
    final cloth = TrainerLooks.outfit[a.outfitColour];
    final clothDeep = Color.lerp(cloth, const Color(0xFF000000), 0.22)!;
    final clothLight = Color.lerp(cloth, const Color(0xFFFFFFFF), 0.28)!;
    const white = Color(0xFFFFFFFF);
    final headW = woman ? 43.0 : (a.gender == 2 ? 45.0 : 46.0);
    final beardOn = !woman;

    // Round background; everything else is clipped to it.
    final disc = Path()..addOval(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.save();
    canvas.clipPath(disc);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      _fill(Tokens.panel),
    );

    // Hood of the hoodie sits behind the neck.
    if (a.outfit == 2) {
      _shape(canvas, _oval(50, 74, 52, 24), clothDeep);
    }

    // Upper body.
    final body = Path()
      ..moveTo(6, 104)
      ..quadraticBezierTo(8, 74, 34, 70)
      ..lineTo(66, 70)
      ..quadraticBezierTo(92, 74, 94, 104)
      ..close();
    if (a.outfit == 6) {
      _shape(canvas, body, skin);
      // Chest line and shoulder shading of the muscle shirt wearer.
      canvas.drawLine(const Offset(50, 78), const Offset(50, 92), _outline);
      final tank = Path()
        ..moveTo(10, 104)
        ..quadraticBezierTo(12, 92, 22, 88)
        ..quadraticBezierTo(36, 86, 38, 71)
        ..lineTo(45, 71)
        ..quadraticBezierTo(50, 84, 55, 71)
        ..lineTo(62, 71)
        ..quadraticBezierTo(64, 86, 78, 88)
        ..quadraticBezierTo(88, 92, 90, 104)
        ..close();
      _shape(canvas, tank, cloth);
    } else {
      _shape(canvas, body, cloth);
    }
    canvas.save();
    canvas.clipPath(body);
    switch (a.outfit) {
      case 0:
        canvas.drawLine(const Offset(50, 80), const Offset(50, 104), _outline);
      case 1:
        // Shoulder seams of the T-shirt.
        for (final x in const [24.0, 76.0]) {
          canvas.drawLine(Offset(x, 80), Offset(x + (x < 50 ? 3 : -3), 104), _thin);
        }
      case 5:
        // Plaid: broad and thin stripes in both directions.
        final broad = _fill(clothDeep.withValues(alpha: 0.55));
        final thin = Paint()
          ..color = _ink.withValues(alpha: 0.35)
          ..strokeWidth = 1;
        for (var i = 0; i < 12; i++) {
          final pos = 8.0 + i * 9;
          canvas.drawRect(Rect.fromLTWH(pos, 60, 4.5, 50), broad);
          canvas.drawRect(Rect.fromLTWH(0, 68 + i * 6.0, 100, 3), broad);
          canvas.drawLine(Offset(pos + 2, 60), Offset(pos + 2, 110), thin);
        }
      case 4:
        // Suit: lapels and the white shirt in between.
        canvas.drawPath(
          Path()
            ..moveTo(36, 70)
            ..lineTo(50, 98)
            ..lineTo(64, 70)
            ..close(),
          _fill(white),
        );
    }
    canvas.restore();
    if (a.outfit == 5) canvas.drawPath(body, _outline);

    // Collars, necklines, buttons and the tie.
    switch (a.outfit) {
      case 0:
        _collar(canvas, clothLight, 34, 70, 40, 66, 50, 80, 50, 74);
        _collar(canvas, clothLight, 66, 70, 60, 66, 50, 80, 50, 74);
      case 1:
        _shape(canvas, _oval(50, 71, 26, 11), skinDeep);
      case 2:
        _shape(canvas, _oval(50, 71, 26, 11), skinDeep);
        for (final x in const [44.0, 56.0]) {
          canvas.drawLine(Offset(x, 76), Offset(x - (x < 50 ? 1 : -1), 94), _outline);
          canvas.drawCircle(Offset(x - (x < 50 ? 1 : -1), 95), 1.6, _fill(white));
        }
      case 3:
        _collar(canvas, clothLight, 36, 70, 42, 65, 50, 79, 50, 72);
        _collar(canvas, clothLight, 64, 70, 58, 65, 50, 79, 50, 72);
        canvas.drawLine(const Offset(50, 79), const Offset(50, 96), _outline);
        for (final y in const [83.0, 91.0]) {
          canvas.drawCircle(Offset(50, y), 1.5, _fill(white));
        }
      case 4:
        final lapelL = Path()
          ..moveTo(34, 70)
          ..lineTo(36, 70)
          ..lineTo(50, 98)
          ..lineTo(40, 98)
          ..close();
        final lapelR = Path()
          ..moveTo(66, 70)
          ..lineTo(64, 70)
          ..lineTo(50, 98)
          ..lineTo(60, 98)
          ..close();
        _shape(canvas, lapelL, clothDeep);
        _shape(canvas, lapelR, clothDeep);
        final tieColour = switch (a.outfitColour) {
          1 || 2 || 5 => const Color(0xFF1F2A5A),
          _ => Tokens.yellow,
        };
        _shape(canvas, _rrect(46, 74, 8, 6, 2), tieColour);
        _shape(
          canvas,
          Path()
            ..moveTo(47, 80)
            ..lineTo(53, 80)
            ..lineTo(56, 98)
            ..lineTo(50, 103)
            ..lineTo(44, 98)
            ..close(),
          tieColour,
        );
      case 5:
        _collar(canvas, clothDeep, 34, 70, 40, 65, 50, 80, 50, 73);
        _collar(canvas, clothDeep, 66, 70, 60, 65, 50, 80, 50, 73);
        canvas.drawLine(const Offset(50, 80), const Offset(50, 104), _outline);
        for (final y in const [86.0, 95.0]) {
          canvas.drawCircle(Offset(50, y), 1.5, _fill(_ink));
        }
    }

    // Long hair and the mullet's tail fall over the shoulders.
    if (a.hairStyle == 4) {
      _shape(canvas, _rrect(21, 24, 58, 70, 24), hair);
    } else if (a.hairStyle == 5) {
      _shape(canvas, _rrect(28, 46, 44, 32, 12), hair);
    }

    // Neck (not for the hood and the tie, they cover it) and a whistle.
    _shape(canvas, _rrect(42, 60, 16, 14, 4), skinDeep);
    if (a.outfit != 4) {
      canvas.drawLine(const Offset(43, 72), const Offset(50, 90), _outline);
      canvas.drawLine(const Offset(57, 72), const Offset(50, 90), _outline);
      _shape(canvas, _rrect(46, 88, 9, 6, 3), Tokens.yellow);
    }

    // Ears and head.
    _shape(canvas, _oval(50 - headW / 2 + 1, 47, 9, 11), skin);
    _shape(canvas, _oval(50 + headW / 2 - 1, 47, 9, 11), skin);
    final head = _oval(50, 44, headW, 52);
    _shape(canvas, head, skin);

    // Beard.
    if (beardOn && a.beard == 1) {
      canvas.save();
      canvas.clipPath(head);
      canvas.drawPath(
        Path()
          ..moveTo(27, 50)
          ..quadraticBezierTo(50, 82, 73, 50)
          ..lineTo(73, 80)
          ..lineTo(27, 80)
          ..close(),
        _fill(hair.withValues(alpha: 0.4)),
      );
      canvas.restore();
    } else if (beardOn && a.beard == 2) {
      final beard = Path()
        ..moveTo(27.5, 48)
        ..quadraticBezierTo(28, 82, 50, 82)
        ..quadraticBezierTo(72, 82, 72.5, 48)
        ..quadraticBezierTo(66, 62, 50, 58)
        ..quadraticBezierTo(34, 62, 27.5, 48)
        ..close();
      _shape(canvas, beard, hair);
    }

    // Eyes: big whites, pupils looking sideways, a shine.
    for (final x in const [40.0, 60.0]) {
      _shape(canvas, _oval(x, 43, 12, 14), white);
      canvas.drawCircle(Offset(x + 1.6, 44), 3.6, _fill(_ink));
      canvas.drawCircle(Offset(x + 2.8, 42.2), 1.2, _fill(white));
    }
    if (woman) {
      // Lashes at the outer corners.
      canvas.drawLine(const Offset(34.5, 38), const Offset(31.5, 35.5), _outline);
      canvas.drawLine(const Offset(34, 41), const Offset(30.5, 40), _outline);
      canvas.drawLine(const Offset(65.5, 38), const Offset(68.5, 35.5), _outline);
      canvas.drawLine(const Offset(66, 41), const Offset(69.5, 40), _outline);
    }
    // Eyebrows: one raised.
    final brow = Paint()
      ..color = a.beard == 0 && a.hairStyle == 0 ? _ink : hairDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = woman ? 2.2 : 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(34, 32), const Offset(45, 30.5), brow);
    canvas.drawLine(const Offset(55, 29), const Offset(66, 31.5), brow);

    // Nose.
    _shape(canvas, _oval(50, 52, 8, 7), skinDeep);

    // Smile: dark mouth, a row of upper teeth, a tongue.
    final mouth = Path()
      ..moveTo(40.5, 59.5)
      ..quadraticBezierTo(50, 62.5, 59.5, 59.5)
      ..quadraticBezierTo(58, 69.5, 50, 69.5)
      ..quadraticBezierTo(42, 69.5, 40.5, 59.5)
      ..close();
    canvas.drawPath(mouth, _fill(const Color(0xFF4A1B1B)));
    canvas.save();
    canvas.clipPath(mouth);
    canvas.drawPath(
      Path()
        ..moveTo(38, 56)
        ..lineTo(62, 56)
        ..lineTo(62, 63.2)
        ..quadraticBezierTo(50, 65.8, 38, 63.2)
        ..close(),
      _fill(const Color(0xFFFFF8E6)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 69.5), width: 11, height: 6),
      _fill(const Color(0xFFE8707A)),
    );
    canvas.restore();
    final lip = Paint()
      ..color = woman ? const Color(0xFFC2304A) : _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = woman ? 2.8 : _line
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(mouth, lip);

    // Moustache.
    if (beardOn && a.beard == 3) {
      final left = Path()
        ..moveTo(50, 56)
        ..quadraticBezierTo(42, 53, 35, 60)
        ..quadraticBezierTo(43, 62, 50, 59)
        ..close();
      final right = Path()
        ..moveTo(50, 56)
        ..quadraticBezierTo(58, 53, 65, 60)
        ..quadraticBezierTo(57, 62, 50, 59)
        ..close();
      _shape(canvas, left, hair);
      _shape(canvas, right, hair);
    }

    // Hair in front.
    switch (a.hairStyle) {
      case 0:
        // Bald: a shine on the head.
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(50, 40), width: 34, height: 40),
          3.6,
          0.7,
          false,
          Paint()
            ..color = white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round,
        );
      case 1:
      case 4:
        _shape(
          canvas,
          Path()
            ..moveTo(26, 40)
            ..quadraticBezierTo(24, 14, 50, 14)
            ..quadraticBezierTo(76, 14, 74, 40)
            ..quadraticBezierTo(66, 26, 50, 26)
            ..quadraticBezierTo(34, 26, 26, 40)
            ..close(),
          hair,
        );
      case 5:
        // Mullet: short and spiky on top.
        _shape(
          canvas,
          Path()
            ..moveTo(27, 38)
            ..lineTo(27, 26)
            ..lineTo(33, 20)
            ..lineTo(38, 13)
            ..lineTo(44, 19)
            ..lineTo(51, 11)
            ..lineTo(57, 19)
            ..lineTo(64, 13)
            ..lineTo(68, 21)
            ..lineTo(73, 27)
            ..lineTo(73, 38)
            ..quadraticBezierTo(66, 27, 50, 27)
            ..quadraticBezierTo(34, 27, 27, 38)
            ..close(),
          hair,
        );
      case 2:
        _shape(
          canvas,
          Path()
            ..moveTo(26, 42)
            ..quadraticBezierTo(22, 12, 52, 13)
            ..quadraticBezierTo(78, 14, 74, 42)
            ..quadraticBezierTo(70, 28, 58, 26)
            ..quadraticBezierTo(42, 30, 26, 42)
            ..close(),
          hair,
        );
      case 3:
        // Curls merge into one outline: ink discs first, hair discs on top.
        const curls = [
          Offset(31, 31),
          Offset(40, 22),
          Offset(51, 19),
          Offset(62, 22),
          Offset(70, 31),
          Offset(27, 42),
          Offset(73, 42),
        ];
        for (final c in curls) {
          canvas.drawCircle(c, 8 + _line / 2, _fill(_ink));
        }
        canvas.drawPath(
          Path()
            ..moveTo(26, 44)
            ..quadraticBezierTo(50, 14, 74, 44)
            ..lineTo(74, 26)
            ..lineTo(26, 26)
            ..close(),
          _fill(_ink),
        );
        for (final c in curls) {
          canvas.drawCircle(c, 8, _fill(hair));
        }
        canvas.drawPath(
          Path()
            ..moveTo(28, 43)
            ..quadraticBezierTo(50, 17, 72, 43)
            ..lineTo(72, 26)
            ..lineTo(28, 26)
            ..close(),
          _fill(hair),
        );
    }

    // Glasses.
    if (a.glasses > 0) {
      final frame = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round;
      final lens = _fill(white.withValues(alpha: 0.28));
      if (a.glasses == 1) {
        for (final x in const [40.0, 60.0]) {
          canvas.drawCircle(Offset(x, 43), 8.5, lens);
          canvas.drawCircle(Offset(x, 43), 8.5, frame);
        }
      } else {
        for (final l in const [31.0, 51.0]) {
          final r = RRect.fromRectAndRadius(
            Rect.fromLTWH(l, 36, 18, 14),
            const Radius.circular(3),
          );
          canvas.drawRRect(r, lens);
          canvas.drawRRect(r, frame);
        }
      }
      canvas.drawLine(const Offset(48.5, 42), const Offset(51.5, 42), frame);
    }

    // Diverse: a small rainbow pin on the chest.
    if (a.gender == 2 && a.outfit != 6) {
      const colours = [
        Color(0xFFE53935),
        Color(0xFFFFC400),
        Color(0xFF2ED47A),
        Color(0xFF3B6FB6),
      ];
      for (var i = 0; i < colours.length; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(30, 96), radius: 7.0 - i * 1.6),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = colours[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.7,
        );
      }
    }
    canvas.restore();

    // Ring around the portrait.
    canvas.drawCircle(
      const Offset(50, 50),
      49,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.restore();
  }

  /// A collar flap: a quadrilateral from the shoulder to the chest.
  void _collar(
    Canvas canvas,
    Color color,
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
    double x4,
    double y4,
  ) {
    _shape(
      canvas,
      Path()
        ..moveTo(x1, y1)
        ..lineTo(x2, y2)
        ..lineTo(x4, y4)
        ..lineTo(x3, y3)
        ..close(),
      color,
    );
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.a != a;
}
