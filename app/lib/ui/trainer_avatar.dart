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
  static const List<Color> jacket = [
    Color(0xFF2E8B57),
    Color(0xFFFFC400),
    Color(0xFFFF7A1A),
    Color(0xFF3B6FB6),
    Color(0xFFC0392B),
    Color(0xFF6B7280),
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

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final skin = TrainerLooks.skin[a.skin];
    final skinDeep = Color.lerp(skin, const Color(0xFF000000), 0.16)!;
    final hair = TrainerLooks.hair[a.hairColour];
    final hairDeep = Color.lerp(hair, const Color(0xFF000000), 0.2)!;
    final jacket = TrainerLooks.jacket[a.jacket];
    const white = Color(0xFFFFFFFF);

    // Round background; everything else is clipped to it.
    final disc = Path()..addOval(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.save();
    canvas.clipPath(disc);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()..color = Tokens.panel,
    );

    // Hair behind the head (long hair, mullet).
    if (a.hairStyle == 4) {
      _shape(canvas, _rrect(22, 22, 56, 62, 22), hair);
    } else if (a.hairStyle == 5) {
      _shape(canvas, _rrect(27, 44, 46, 32, 12), hair);
    }

    // Jacket with collar and zip.
    final body = Path()
      ..moveTo(6, 104)
      ..quadraticBezierTo(8, 74, 34, 70)
      ..lineTo(66, 70)
      ..quadraticBezierTo(92, 74, 94, 104)
      ..close();
    _shape(canvas, body, jacket);
    canvas.drawLine(const Offset(50, 80), const Offset(50, 104), _outline);
    final collarL = Path()
      ..moveTo(50, 80)
      ..lineTo(34, 70)
      ..lineTo(40, 66)
      ..lineTo(50, 74)
      ..close();
    final collarR = Path()
      ..moveTo(50, 80)
      ..lineTo(66, 70)
      ..lineTo(60, 66)
      ..lineTo(50, 74)
      ..close();
    _shape(canvas, collarL, Color.lerp(jacket, white, 0.25)!);
    _shape(canvas, collarR, Color.lerp(jacket, white, 0.25)!);

    // Neck and a whistle on a cord.
    _shape(canvas, _rrect(42, 60, 16, 14, 4), skinDeep);
    canvas.drawLine(const Offset(43, 72), const Offset(50, 90), _outline);
    canvas.drawLine(const Offset(57, 72), const Offset(50, 90), _outline);
    _shape(canvas, _rrect(46, 88, 9, 6, 3), Tokens.yellow);

    // Ears and head.
    _shape(canvas, _oval(27.5, 47, 9, 11), skin);
    _shape(canvas, _oval(72.5, 47, 9, 11), skin);
    final head = _oval(50, 44, 46, 52);
    _shape(canvas, head, skin);

    // Beard (below the face features, above the skin).
    if (a.beard == 1) {
      canvas.save();
      canvas.clipPath(head);
      canvas.drawPath(
        Path()
          ..moveTo(27, 50)
          ..quadraticBezierTo(50, 82, 73, 50)
          ..lineTo(73, 80)
          ..lineTo(27, 80)
          ..close(),
        Paint()..color = hair.withValues(alpha: 0.4),
      );
      canvas.restore();
    } else if (a.beard == 2) {
      final beard = Path()
        ..moveTo(27, 48)
        ..quadraticBezierTo(28, 82, 50, 82)
        ..quadraticBezierTo(72, 82, 73, 48)
        ..quadraticBezierTo(66, 62, 50, 58)
        ..quadraticBezierTo(34, 62, 27, 48)
        ..close();
      _shape(canvas, beard, hair);
    }

    // Eyes: big whites, pupils looking sideways, a shine.
    for (final x in const [40.0, 60.0]) {
      _shape(canvas, _oval(x, 43, 12, 14), white);
      canvas.drawCircle(Offset(x + 1.6, 44), 3.6, Paint()..color = _ink);
      canvas.drawCircle(Offset(x + 2.8, 42.2), 1.2, Paint()..color = white);
    }
    // Eyebrows: thick, one raised.
    final brow = Paint()
      ..color = a.beard == 0 && a.hairStyle == 0 ? _ink : hairDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(34, 33), const Offset(45, 31), brow);
    canvas.drawLine(const Offset(55, 29.5), const Offset(66, 32), brow);

    // Nose.
    _shape(canvas, _oval(50, 52, 8, 7), skinDeep);

    // Grin with teeth.
    final grin = Path()
      ..moveTo(40, 60)
      ..quadraticBezierTo(50, 62, 60, 60)
      ..quadraticBezierTo(58, 70, 50, 70)
      ..quadraticBezierTo(42, 70, 40, 60)
      ..close();
    if (a.beard == 2) {
      canvas.drawPath(grin, Paint()..color = const Color(0xFF3A1212));
      canvas.drawPath(grin, _outline);
    } else {
      _shape(canvas, grin, white);
    }
    canvas.drawLine(
      const Offset(50, 61.2),
      const Offset(50, 69.5),
      Paint()
        ..color = _ink
        ..strokeWidth = 1,
    );

    // Moustache.
    if (a.beard == 3) {
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
      case 5:
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
        for (final c in const [
          Offset(31, 31),
          Offset(40, 22),
          Offset(51, 19),
          Offset(62, 22),
          Offset(70, 31),
          Offset(27, 42),
          Offset(73, 42),
        ]) {
          _shape(
            canvas,
            Path()..addOval(Rect.fromCircle(center: c, radius: 8)),
            hair,
          );
        }
        // Cover the inner outlines so the curls read as one mass.
        canvas.drawPath(
          Path()
            ..moveTo(34, 38)
            ..quadraticBezierTo(50, 22, 66, 38)
            ..lineTo(66, 30)
            ..lineTo(34, 30)
            ..close(),
          Paint()..color = hair,
        );
    }

    // Glasses.
    if (a.glasses > 0) {
      final frame = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round;
      final lens = Paint()..color = white.withValues(alpha: 0.28);
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

  @override
  bool shouldRepaint(_AvatarPainter old) => old.a != a;
}
