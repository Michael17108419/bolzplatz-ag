import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../game/desk.dart';
import '../theme/tokens.dart';
import 'adaptive.dart';
import 'crest.dart';
import 'office_svgs.dart';

/// Where each desk item was drawn (1600 x 900 sheet of the first stage);
/// the room is laid out anew, see [officePlace].
const Map<DeskItem, Rect> _baseSpots = {
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

/// A rectangle in a layer's own drawing, moved to where the layer sits.
Rect _placed(String layer, Rect r) {
  final p = officePlace[layer];
  if (p == null) return r;
  final (k, tx, ty) = p;
  return Rect.fromLTWH(r.left * k + tx, r.top * k + ty, r.width * k, r.height * k);
}

/// Where each desk item sits in the 1500 x 900 room (the click areas).
final Map<DeskItem, Rect> deskSpots = {
  for (final e in _baseSpots.entries)
    e.key: _placed(
      switch (e.key) {
        DeskItem.post => 'mail',
        DeskItem.saves => 'drawer',
        _ => e.key.name,
      },
      e.value,
    ),
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
    this.calendarTop = '',
    this.calendarDay = '',
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

  /// The date on the desk calendar: weekday and month on the red band, the
  /// day of the month large below.
  final String calendarTop;
  final String calendarDay;

  /// Number of won titles shown in the cabinet (at most six).
  final int trophies;

  @override
  State<OfficeScene> createState() => _OfficeSceneState();
}

class _OfficeSceneState extends State<OfficeScene> {
  DeskItem? _hover;
  late List<String> _svgs;

  /// Only used when the scene is wider than the screen (a phone held
  /// upright): the view then snaps to a few zones of the room.
  final ScrollController _controller = ScrollController();
  List<double> _stops = const [];
  double _viewW = 0;
  double _scale = 0;
  double _lastScale = 0;
  int _zone = -1;

  /// The zones of the room, as the left edge in scene units, and the width
  /// of the view on a phone. Every desk item lies whole in at least one.
  static const _zoneStarts = [0.0, 500.0, 1000.0];
  static const _zoneW = 500.0;
  static const _floor = Color(0xFF2A1D14);

  @override
  void initState() {
    super.initState();
    _svgs = _paint(widget.clubId);
    _controller.addListener(_track);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _track() {
    if (_stops.isEmpty || !_controller.hasClients) return;
    _zone = _nearestStop(_controller.offset);
  }

  /// The name tag stays inside the zone (500 units) its thing stands in.
  double _tagLeft(double centerX, double scale) {
    final panel = (centerX ~/ _zoneW) * _zoneW;
    return (centerX * scale - 75)
        .clamp(panel * scale + 4, (panel + _zoneW) * scale - 150 - 4)
        .toDouble();
  }

  int _nearestStop(double offset) {
    var best = 0;
    for (var i = 1; i < _stops.length; i++) {
      if ((_stops[i] - offset).abs() < (_stops[best] - offset).abs()) best = i;
    }
    return best;
  }

  /// The more urgent a thing, the earlier: post, calendar, then the rest.
  static final List<DeskItem> _priority = [
    DeskItem.post,
    DeskItem.calendar,
    ...DeskItem.values.where(
      (i) => i != DeskItem.post && i != DeskItem.calendar,
    ),
  ];

  /// The zone in which the item lies whole (or the nearest one).
  int _zoneOf(DeskItem item) {
    final spot = deskSpots[item]!;
    for (var i = 0; i < _stops.length; i++) {
      if (spot.left * _scale >= _stops[i] - 1 &&
          spot.right * _scale <= _stops[i] + _viewW + 1) {
        return i;
      }
    }
    return _nearestStop(spot.center.dx * _scale - _viewW / 2);
  }

  DeskItem? _mostUrgent(Iterable<DeskItem> items) {
    for (final i in _priority) {
      if (items.contains(i)) return i;
    }
    return null;
  }

  void _place() {
    final target = _stops[_zone.clamp(0, _stops.length - 1)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) _controller.jumpTo(target);
    });
  }

  void _goTo(int zone) {
    _controller.animateTo(
      _stops[zone],
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
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

  static const _sceneW = officeW;
  static const _canvasH = officeH;
  static const _coreH = officeCoreH;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // On a phone held upright only a part of the room fits the width:
        // the scene is then wider than the screen and shows in zones.
        final narrow = isNarrow(context);
        // On a phone the view is at least one zone wide and shows all of the
        // picture proper; a taller screen shows more of the floor below it.
        final scale = narrow
            ? math.min(box.maxWidth / _zoneW, box.maxHeight / (_coreH - 10))
            : math.min(box.maxWidth / _sceneW, box.maxHeight / _coreH);
        final w = _sceneW * scale;
        final h = narrow ? box.maxHeight : _coreH * scale;
        final scrolls = w > box.maxWidth + 0.5;
        final viewW = scrolls ? box.maxWidth : w;
        if (scrolls) {
          final stops = <double>[];
          for (final z in _zoneStarts) {
            final s = (z * scale).clamp(0.0, w - viewW).toDouble();
            if (stops.isEmpty || (s - stops.last).abs() > 1) stops.add(s);
          }
          _stops = stops;
          _viewW = viewW;
          _scale = scale;
          if (_zone < 0) {
            // First look: where something waits, otherwise the desk.
            final urgent = _mostUrgent(widget.badges.keys);
            _zone = urgent == null
                ? math.min(1, stops.length - 1)
                : _zoneOf(urgent);
            _place();
          } else if ((scale - _lastScale).abs() > 1e-6) {
            _place();
          }
          _lastScale = scale;
        } else {
          _stops = const [];
          _zone = -1;
        }
        Rect r(Rect s) => Rect.fromLTWH(
          s.left * scale,
          s.top * scale,
          s.width * scale,
          s.height * scale,
        );
        final theme = Theme.of(context);
        final hover = _hover;

        final children = <Widget>[
          const Positioned.fill(child: ColoredBox(color: _floor)),
          for (final svg in _svgs)
            Positioned(
              left: 0,
              top: 0,
              width: w,
              height: _canvasH * scale,
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
            rect: r(_placed('stats', const Rect.fromLTWH(1058, 146, 88, 26))),
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
            rect: r(_placed('frame', const Rect.fromLTWH(1224, 614, 44, 66))),
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
                _placed(
                  'stats',
                  Rect.fromLTWH(
                    1230.0 + (i % 3) * 65 - 22,
                    (i < 3 ? 236.0 : 336.0) - 58,
                    44,
                    58,
                  ),
                ),
              ),
              child: const CustomPaint(painter: _CupPainter()),
            ),
          // The date on the desk calendar.
          Positioned.fromRect(
            rect: r(_placed('calendar', const Rect.fromLTWH(802, 646, 70, 24))),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.calendarTop,
                  key: const ValueKey('calendar-top'),
                  style: const TextStyle(
                    fontFamily: Tokens.headlineFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: r(_placed('calendar', const Rect.fromLTWH(802, 670, 70, 48))),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.calendarDay,
                  key: const ValueKey('calendar-day'),
                  style: const TextStyle(
                    fontFamily: Tokens.headlineFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 40,
                    height: 1,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ),
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
          // On a phone the names stand at the things (no hovering there).
          if (scrolls)
            for (final item in DeskItem.values)
              if (widget.labels[item] != null)
                Positioned(
                  left: _tagLeft(deskSpots[item]!.center.dx, scale),
                  width: 150,
                  top: deskSpots[item]!.bottom * scale - 22,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        key: ValueKey('desk-name-${item.name}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC1B2E22),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                          widget.labels[item]!.title,
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: Tokens.headlineFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            height: 1.2,
                            color: Tokens.cream,
                          ),
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
          if (hover != null && widget.labels[hover] != null)
            _label(theme, hover, widget.labels[hover]!, scale, w, h),
        ];

        final stack = SizedBox(
          width: w,
          height: h,
          child: Stack(clipBehavior: Clip.hardEdge, children: children),
        );
        if (!scrolls) {
          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: stack,
              ),
            ),
          );
        }
        final stops = _stops;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: viewW,
            height: h,
            child: Stack(
              children: [
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                    scrollbars: false,
                  ),
                  child: SingleChildScrollView(
                    key: const ValueKey('office-zones'),
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    physics: _ZoneSnapPhysics(
                      stops: stops,
                      parent: const ClampingScrollPhysics(),
                    ),
                    child: stack,
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => _edgeHints(viewW, h, stops),
                  ),
                ),
                // The dots that show the view stand on the floor.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 34,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => _dots(stops),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double get _offset => _controller.hasClients
      ? _controller.offset
      : (_stops.isEmpty ? 0 : _stops[_zone.clamp(0, _stops.length - 1)]);

  Widget _dots(List<double> stops) {
    final now = _nearestStop(_offset);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < stops.length; i++)
          Container(
            key: ValueKey('zone-dot-$i'),
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Drawn like the rest of the room: outline, flat colour.
              color: i == now ? Tokens.yellow : const Color(0xFF2E8B57),
              border: Border.all(color: const Color(0xFF2B1B12), width: 2.5),
            ),
          ),
      ],
    );
  }

  /// A mark at the edge of the view when something waits in a zone that is
  /// out of sight; a tap takes you there.
  Widget _edgeHints(double viewW, double h, List<double> stops) {
    final offset = _offset;
    final left = <DeskItem>[];
    final right = <DeskItem>[];
    for (final item in widget.badges.keys) {
      final c = deskSpots[item]!.center.dx * _scale;
      if (c < offset) {
        left.add(item);
      } else if (c > offset + viewW) {
        right.add(item);
      }
    }
    Widget pill(DeskItem item, bool toRight) => Positioned(
      left: toRight ? null : 6,
      right: toRight ? 6 : null,
      top: h * 0.42,
      child: GestureDetector(
        key: ValueKey('zone-hint-${toRight ? 'right' : 'left'}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _goTo(_zoneOf(item)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Tokens.yellow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Tokens.ink, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!toRight) _hintArrow(false),
              Text(
                '${widget.labels[item]?.title ?? ''} ${widget.badges[item]}',
                style: const TextStyle(
                  fontFamily: Tokens.headlineFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Tokens.ink,
                ),
              ),
              if (toRight) _hintArrow(true),
            ],
          ),
        ),
      ),
    );
    final l = _mostUrgent(left);
    final r = _mostUrgent(right);
    return Stack(
      children: [
        if (l != null) pill(l, false),
        if (r != null) pill(r, true),
      ],
    );
  }

  Widget _hintArrow(bool forward) => SizedBox(
    width: 16,
    height: 16,
    child: CustomPaint(painter: _HintArrowPainter(forward)),
  );

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

class _HintArrowPainter extends CustomPainter {
  const _HintArrowPainter(this.forward);

  final bool forward;

  @override
  void paint(Canvas canvas, Size size) {
    final d = forward ? 1.0 : -1.0;
    final c = size.center(Offset.zero);
    final path = Path()
      ..moveTo(c.dx - 4 * d, c.dy - 6)
      ..lineTo(c.dx + 5 * d, c.dy)
      ..lineTo(c.dx - 4 * d, c.dy + 6)
      ..close();
    canvas.drawPath(path, Paint()..color = Tokens.ink);
  }

  @override
  bool shouldRepaint(_HintArrowPainter old) => old.forward != forward;
}

/// Lets the horizontal view come to rest only at one of the zone stops.
class _ZoneSnapPhysics extends ScrollPhysics {
  const _ZoneSnapPhysics({required this.stops, super.parent});

  final List<double> stops;

  @override
  _ZoneSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _ZoneSnapPhysics(stops: stops, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.outOfRange || stops.isEmpty) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final pos = position.pixels;
    double target;
    if (velocity.abs() < tolerance.velocity) {
      target = stops.reduce(
        (a, b) => (a - pos).abs() <= (b - pos).abs() ? a : b,
      );
    } else if (velocity > 0) {
      target = stops.firstWhere((s) => s > pos + 1, orElse: () => stops.last);
    } else {
      target = stops.lastWhere((s) => s < pos - 1, orElse: () => stops.first);
    }
    if ((target - pos).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      pos,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
