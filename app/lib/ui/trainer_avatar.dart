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
  static const List<Color> jacket = [
    Color(0xFF2E8B57),
    Color(0xFFFFC400),
    Color(0xFFFF7A1A),
    Color(0xFF3B6FB6),
    Color(0xFFC0392B),
    Color(0xFF6B7280),
  ];
}

/// The trainer as a small portrait in the calm flat style of the crests.
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

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final skin = TrainerLooks.skin[a.skin];
    final skinDeep = Color.lerp(skin, const Color(0xFF000000), 0.18)!;
    final hair = TrainerLooks.hair[a.hairColour];
    final jacket = TrainerLooks.jacket[a.jacket];
    const ink = Color(0xFF1A1300);

    Paint fill(Color c) => Paint()..color = c;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Round background; everything else is clipped to it.
    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, 100, 100)));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), fill(Tokens.panel));

    // Hair behind the head (long hair, mullet).
    if (a.hairStyle == 4) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(28, 24, 44, 50),
          const Radius.circular(14),
        ),
        fill(hair),
      );
    } else if (a.hairStyle == 5) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(32, 38, 36, 30),
          const Radius.circular(10),
        ),
        fill(hair),
      );
    }

    // Neck and jacket.
    canvas.drawRect(const Rect.fromLTWH(43, 58, 14, 16), fill(skinDeep));
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(14, 72, 72, 40),
        topLeft: const Radius.circular(22),
        topRight: const Radius.circular(22),
      ),
      fill(jacket),
    );
    final collar = Path()
      ..moveTo(40, 72)
      ..lineTo(50, 86)
      ..lineTo(60, 72)
      ..close();
    canvas.drawPath(collar, fill(skinDeep));
    canvas.drawLine(
      const Offset(50, 86),
      const Offset(50, 104),
      Paint()
        ..color = Tokens.cream
        ..strokeWidth = 1.6,
    );

    // Head and ears.
    canvas.drawCircle(const Offset(33, 45), 4, fill(skinDeep));
    canvas.drawCircle(const Offset(67, 45), 4, fill(skinDeep));
    final head = Rect.fromCenter(
      center: const Offset(50, 42),
      width: 36,
      height: 42,
    );
    canvas.drawOval(head, fill(skin));

    // Eyes and mouth.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(43, 42), width: 3.4, height: 4),
      fill(ink),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(57, 42), width: 3.4, height: 4),
      fill(ink),
    );
    final mouth = Path()
      ..moveTo(45, 54)
      ..quadraticBezierTo(50, 57, 55, 54);

    // Beard.
    switch (a.beard) {
      case 1:
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(50, 46), width: 35, height: 36),
          0,
          math.pi,
          true,
          fill(hair.withValues(alpha: 0.35)),
        );
      case 2:
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(50, 46), width: 36, height: 40),
          0.1,
          math.pi - 0.2,
          true,
          fill(hair),
        );
      case 3:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(42, 48.5, 16, 4.5),
            const Radius.circular(2.2),
          ),
          fill(hair),
        );
    }
    if (a.beard == 2) {
      canvas.drawPath(mouth, stroke..color = skin);
      stroke.color = ink;
    } else {
      canvas.drawPath(mouth, stroke);
    }

    // Hair in front.
    final cap = Rect.fromCenter(
      center: const Offset(50, 40),
      width: 38,
      height: 46,
    );
    switch (a.hairStyle) {
      case 1:
      case 4:
      case 5:
        canvas.drawArc(cap, math.pi, math.pi, true, fill(hair));
      case 2:
        canvas.drawArc(cap, math.pi, math.pi, true, fill(hair));
        final fringe = Path()
          ..moveTo(31, 38)
          ..quadraticBezierTo(46, 22, 69, 31)
          ..lineTo(69, 40)
          ..quadraticBezierTo(52, 28, 36, 40)
          ..close();
        canvas.drawPath(fringe, fill(hair));
      case 3:
        for (final c in const [
          Offset(35, 30),
          Offset(43, 24),
          Offset(51, 22),
          Offset(59, 24),
          Offset(66, 30),
          Offset(32, 38),
          Offset(68, 38),
        ]) {
          canvas.drawCircle(c, 6.2, fill(hair));
        }
    }

    // Glasses.
    if (a.glasses > 0) {
      final frame = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      if (a.glasses == 1) {
        canvas.drawCircle(const Offset(43, 42), 6, frame);
        canvas.drawCircle(const Offset(57, 42), 6, frame);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(36, 37, 14, 10),
            const Radius.circular(2),
          ),
          frame,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(50, 37, 14, 10),
            const Radius.circular(2),
          ),
          frame,
        );
      }
      canvas.drawLine(const Offset(49, 42), const Offset(51, 42), frame);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.a != a;
}
