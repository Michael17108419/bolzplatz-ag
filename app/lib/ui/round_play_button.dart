import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The round yellow play button: on to the next day. A shadow, an outline and
/// a plain triangle, like the rest of the room. With [pause] it shows two
/// bars instead (the game is running).
class RoundPlayButton extends StatelessWidget {
  const RoundPlayButton({
    required this.semanticLabel,
    required this.onTap,
    this.pause = false,
    super.key,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final bool pause;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(painter: _PlayPainter(pause: pause)),
          ),
        ),
      ),
    );
  }
}

class _PlayPainter extends CustomPainter {
  const _PlayPainter({required this.pause});

  final bool pause;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 - 2);
    const ink = Color(0xFF2B1B12);
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 25), width: 40, height: 8),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawCircle(c, 24, Paint()..color = Tokens.yellow);
    canvas.drawCircle(
      c,
      24,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ink,
    );
    if (pause) {
      for (final dx in const [-6.0, 6.0]) {
        final bar = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c + Offset(dx, 0), width: 6, height: 22),
          const Radius.circular(2),
        );
        canvas.drawRRect(bar, Paint()..color = ink);
      }
      return;
    }
    final tri = Path()
      ..moveTo(c.dx - 7, c.dy - 12)
      ..lineTo(c.dx + 13, c.dy)
      ..lineTo(c.dx - 7, c.dy + 12)
      ..close();
    canvas.drawPath(tri, Paint()..color = ink);
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = ink,
    );
  }

  @override
  bool shouldRepaint(_PlayPainter old) => old.pause != pause;
}
