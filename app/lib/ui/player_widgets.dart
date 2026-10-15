import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../theme/tokens.dart';

/// The colour of an attribute or strength value: orange weak (under 40),
/// beige average, green good (from 60), yellow top (from 80).
Color valueColor(double v) {
  if (v < 40) return Tokens.orange;
  if (v < 60) return Tokens.beige;
  if (v < 80) return Tokens.green;
  return Tokens.yellow;
}

/// The colour of a position group: goalkeeper, defence, midfield, attack.
Color positionColor(Position p) => switch (p) {
  Position.tw => Tokens.orange,
  Position.iv || Position.lv || Position.rv => Tokens.green,
  Position.zdm || Position.zm || Position.zom => Tokens.yellow,
  Position.la || Position.ra || Position.st => const Color(0xFFE8685C),
};

/// A small rounded tag with the position id.
class PositionChip extends StatelessWidget {
  const PositionChip(this.position, {this.width, super.key});

  final Position position;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final color = positionColor(position);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Tokens.ground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        position.id,
        maxLines: 1,
        style: TextStyle(
          fontFamily: Tokens.headlineFont,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          height: 1.1,
          color: color,
        ),
      ),
    );
  }
}

/// A bronze, silver or gold dot for a special ability.
class Medal extends StatelessWidget {
  const Medal(this.tier, {this.size = 14, super.key});

  final AbilityTier tier;
  final double size;

  static Color colorOf(AbilityTier tier) => switch (tier) {
    AbilityTier.bronze => const Color(0xFFC07A3C),
    AbilityTier.silver => const Color(0xFFC9CDD6),
    AbilityTier.gold => Tokens.yellow,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorOf(tier),
        border: Border.all(color: Tokens.ink, width: 2),
      ),
    );
  }
}

/// A horizontal bar from 1 to 100 in the colour of its class.
class ValueBar extends StatelessWidget {
  const ValueBar(this.value, {this.height = 10, super.key});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / 100).clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Tokens.ground,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction,
        child: Container(
          decoration: BoxDecoration(
            color: valueColor(value),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

/// Filled and empty dots, for example the weak foot or the potential.
class Dots extends StatelessWidget {
  const Dots(this.filled, {this.total = 5, super.key});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? Tokens.yellow : Tokens.ground,
              border: Border.all(
                color: i < filled ? Tokens.yellow : Tokens.beige,
                width: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}

/// A bar of four steps (low, middle, high, extreme) with [level] filled.
class LevelBar extends StatelessWidget {
  const LevelBar(this.level, {super.key});

  final int level;

  @override
  Widget build(BuildContext context) {
    const colors = [
      Tokens.beige,
      Tokens.beige,
      Tokens.green,
      Tokens.yellow,
    ];
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: i <= level ? colors[level] : Tokens.ground,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 3),
        ],
      ],
    );
  }
}

/// A small triangle that shows the direction of a sort.
class SortCaret extends StatelessWidget {
  const SortCaret({required this.up, super.key});

  final bool up;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(9, 6),
      painter: _CaretPainter(up),
    );
  }
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter(this.up);

  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (up) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width / 2, 0);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height);
    }
    canvas.drawPath(path..close(), Paint()..color = Tokens.yellow);
  }

  @override
  bool shouldRepaint(_CaretPainter old) => old.up != up;
}
