import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../game/desk.dart';
import '../theme/tokens.dart';
import 'crest.dart';
import 'office_svgs.dart';

/// Where each desk item sits in the 1600 x 900 scene (the click areas).
const Map<DeskItem, Rect> deskSpots = {
  DeskItem.post: Rect.fromLTWH(270, 560, 200, 180),
  DeskItem.press: Rect.fromLTWH(490, 680, 265, 100),
  DeskItem.tactics: Rect.fromLTWH(60, 96, 310, 240),
  DeskItem.files: Rect.fromLTWH(30, 330, 310, 365),
  DeskItem.calendar: Rect.fromLTWH(780, 612, 110, 140),
  DeskItem.stats: Rect.fromLTWH(1030, 120, 380, 255),
  DeskItem.transfers: Rect.fromLTWH(390, 140, 180, 185),
  DeskItem.finance: Rect.fromLTWH(930, 640, 275, 135),
  DeskItem.grounds: Rect.fromLTWH(590, 84, 420, 290),
  DeskItem.saves: Rect.fromLTWH(996, 806, 330, 68),
  DeskItem.door: Rect.fromLTWH(1432, 98, 166, 560),
};

/// The sign that appears when the mouse rests on a desk item.
class DeskLabel {
  const DeskLabel({
    required this.title,
    required this.hint,
    required this.keyText,
  });

  final String title;
  final String hint;
  final String keyText;
}

/// The office as a picture: a desk with things on it, each one a button.
///
/// The picture is 16:9 and scales with the window, the click areas scale
/// with it. The club colour paints the wall band and the rug (level 1 of the
/// club's influence), the crest hangs on the wall and the trainer stands in
/// the frame on the desk; the trophy cabinet fills with won titles (level 2).
class OfficeScene extends StatefulWidget {
  const OfficeScene({
    required this.clubId,
    required this.labels,
    required this.badges,
    required this.onOpen,
    required this.portrait,
    required this.leagueLabel,
    this.trophies = 0,
    super.key,
  });

  final int clubId;
  final Map<DeskItem, DeskLabel> labels;

  /// Small badge text per item (a count or "!"); items without one have none.
  final Map<DeskItem, String> badges;
  final void Function(DeskItem item) onOpen;

  /// Builds the trainer portrait for the given edge length.
  final Widget Function(double size) portrait;
  final String leagueLabel;

  /// Number of won titles shown in the cabinet (at most six).
  final int trophies;

  @override
  State<OfficeScene> createState() => _OfficeSceneState();
}

class _OfficeSceneState extends State<OfficeScene> {
  DeskItem? _hover;
  late List<String> _svgs;

  @override
  void initState() {
    super.initState();
    _svgs = _paint(widget.clubId);
  }

  @override
  void didUpdateWidget(OfficeScene old) {
    super.didUpdateWidget(old);
    if (old.clubId != widget.clubId) _svgs = _paint(widget.clubId);
  }

  static List<String> _paint(int clubId) {
    final spec = CrestSpec.forClub(clubId);
    return [
      for (final (_, svg) in officeLayers)
        svg
            .replaceAll('{{clubDark}}', spec.deepHex)
            .replaceAll('{{clubLight}}', spec.lightHex)
            .replaceAll('{{club}}', spec.fieldHex),
    ];
  }

  static const _sceneW = 1600.0;
  static const _sceneH = 900.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final scale = math.min(box.maxWidth / _sceneW, box.maxHeight / _sceneH);
        final w = _sceneW * scale;
        final h = _sceneH * scale;
        Rect r(Rect s) => Rect.fromLTWH(
          s.left * scale,
          s.top * scale,
          s.width * scale,
          s.height * scale,
        );
        final theme = Theme.of(context);
        final hover = _hover;

        final children = <Widget>[
          for (final svg in _svgs)
            Positioned.fill(
              child: SvgPicture.string(
                svg,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
          // The club's crest on the wall.
          Positioned.fromRect(
            rect: r(const Rect.fromLTWH(760, 392, 80, 88)),
            child: ClubCrest(clubId: widget.clubId, size: 88 * scale),
          ),
          // The league on the poster banner.
          Positioned.fromRect(
            rect: r(const Rect.fromLTWH(1058, 146, 88, 26)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.leagueLabel,
                style: const TextStyle(
                  fontFamily: Tokens.headlineFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Tokens.cream,
                ),
              ),
            ),
          ),
          // The trainer in the frame on the desk.
          Positioned.fromRect(
            rect: r(const Rect.fromLTWH(1224, 614, 44, 66)),
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: widget.portrait(100),
                ),
              ),
            ),
          ),
          // Won titles in the cabinet.
          for (var i = 0; i < math.min(widget.trophies, 6); i++)
            Positioned.fromRect(
              rect: r(
                Rect.fromLTWH(
                  1230.0 + (i % 3) * 65 - 22,
                  (i < 3 ? 236.0 : 336.0) - 58,
                  44,
                  58,
                ),
              ),
              child: const CustomPaint(painter: _CupPainter()),
            ),
          // The click areas.
          for (final item in DeskItem.values)
            Positioned.fromRect(
              rect: r(deskSpots[item]!),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hover = item),
                onExit: (_) => setState(() {
                  if (_hover == item) _hover = null;
                }),
                child: GestureDetector(
                  key: ValueKey('desk-${item.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onOpen(item),
                  child: Semantics(
                    button: true,
                    label: widget.labels[item]?.title,
                    child: DecoratedBox(
                      decoration: hover == item
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Tokens.yellow,
                                width: 3,
                              ),
                              color: const Color(0x1FFFC400),
                            )
                          : const BoxDecoration(),
                    ),
                  ),
                ),
              ),
            ),
          // The badges that show where something waits.
          for (final e in widget.badges.entries)
            Positioned(
              left: (deskSpots[e.key]!.right - 26) * scale,
              top: (deskSpots[e.key]!.top - 10) * scale,
              child: IgnorePointer(
                child: Container(
                  key: ValueKey('badge-${e.key.name}'),
                  constraints: const BoxConstraints(minWidth: 26),
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Tokens.yellow,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Tokens.ink, width: 2),
                  ),
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontFamily: Tokens.headlineFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1,
                      color: Tokens.ink,
                    ),
                  ),
                ),
              ),
            ),
          if (hover != null && widget.labels[hover] != null)
            _label(theme, hover, widget.labels[hover]!, scale, w, h),
        ];

        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(clipBehavior: Clip.none, children: children),
            ),
          ),
        );
      },
    );
  }

  Widget _label(
    ThemeData theme,
    DeskItem item,
    DeskLabel label,
    double scale,
    double w,
    double h,
  ) {
    final spot = deskSpots[item]!;
    final left = ((spot.center.dx * scale) - 140)
        .clamp(4.0, math.max(4.0, w - 284))
        .toDouble();
    final above = spot.top * scale > 110;
    final card = IgnorePointer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          key: const ValueKey('desk-label'),
          padding: const EdgeInsets.all(Tokens.gapS + 2),
          decoration: BoxDecoration(
            color: Tokens.ground,
            borderRadius: BorderRadius.circular(Tokens.radius),
            border: Border.all(color: Tokens.yellow, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      label.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Tokens.yellow,
                      ),
                    ),
                  ),
                  const SizedBox(width: Tokens.gapS),
                  Text(label.keyText, style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 2),
              Text(label.hint, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
    return above
        ? Positioned(left: left, bottom: h - spot.top * scale + 6, child: card)
        : Positioned(left: left, top: spot.bottom * scale + 6, child: card);
  }
}

/// A small gold cup for a won title.
class _CupPainter extends CustomPainter {
  const _CupPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 120);
    final fill = Paint()..color = const Color(0xFFE7C65A);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2B1B12);
    final handles = Path()
      ..moveTo(20, 22)
      ..cubicTo(-8, 22, -4, 56, 28, 56)
      ..moveTo(80, 22)
      ..cubicTo(108, 22, 104, 56, 72, 56);
    canvas.drawPath(handles, line);
    final bowl = Path()
      ..moveTo(18, 8)
      ..lineTo(82, 8)
      ..quadraticBezierTo(82, 72, 50, 78)
      ..quadraticBezierTo(18, 72, 18, 8)
      ..close();
    canvas.drawPath(bowl, fill);
    canvas.drawPath(bowl, line);
    const stem = Rect.fromLTWH(43, 78, 14, 20);
    canvas.drawRect(stem, fill);
    canvas.drawRect(stem, line);
    final base = RRect.fromRectAndRadius(
      const Rect.fromLTWH(26, 98, 48, 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(base, fill);
    canvas.drawRRect(base, line);
  }

  @override
  bool shouldRepaint(_CupPainter old) => false;
}
