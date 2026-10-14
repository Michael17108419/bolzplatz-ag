import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// What a club crest looks like: one shape, one symbol, one club colour.
/// The choice is a fixed function of the club id, so a club keeps its crest.
class CrestSpec {
  const CrestSpec({
    required this.shape,
    required this.symbol,
    required this.color,
  });

  factory CrestSpec.forClub(int clubId) {
    // A small integer mix, so neighbouring ids get unrelated crests.
    var h = (clubId * 2654435761) & 0xFFFFFFFF;
    h ^= h >> 15;
    h = (h * 2246822519) & 0xFFFFFFFF;
    h ^= h >> 13;
    return CrestSpec(
      shape: h % _shapes.length,
      symbol: (h ~/ 7) % _symbols.length,
      color: (h ~/ 70) % _colors.length,
    );
  }

  final int shape;
  final int symbol;
  final int color;

  /// Main colour of the crest.
  Color get fieldColor => Color(_colors[color]);

  String toSvg() {
    final field = _hex(_colors[color]);
    final deep = _hex(_darken(_colors[color]));
    final path = _shapes[shape];
    const cream = '#F4EFE2';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 110">'
        '<defs><clipPath id="c"><path d="$path"/></clipPath></defs>'
        '<g clip-path="url(#c)"><rect width="100" height="110" fill="$field"/>'
        '</g>'
        '<path d="$path" fill="none" stroke="$cream" stroke-width="4" '
        'stroke-linejoin="round"/>'
        '${_symbols[symbol](field, deep)}'
        '</svg>';
  }

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static int _darken(int argb) {
    int part(int shift) => (((argb >> shift) & 0xFF) * 0.55).round();
    return 0xFF000000 | (part(16) << 16) | (part(8) << 8) | part(0);
  }

  static const List<String> _shapes = [
    'M50 9 A46 46 0 1 1 49.99 9 Z',
    'M10 8 H90 V60 L50 106 L10 60 Z',
    'M10 8 H90 V62 A40 40 0 0 1 10 62 Z',
    'M50 4 L90 27 V83 L50 106 L10 83 V27 Z',
    'M10 104 V44 A40 40 0 0 1 90 44 V104 Z',
    'M12 8 H88 V70 Q88 100 50 106 Q12 100 12 70 Z',
    'M50 4 L96 55 L50 106 L4 55 Z',
  ];

  /// Muted club colours; each reads well with cream on top.
  static const List<int> _colors = [
    0xFFA8232D, // red
    0xFF1B3A6B, // navy
    0xFF1F5A3A, // forest
    0xFF4B2A7B, // purple
    0xFF1F6A6A, // teal
    0xFF8A5A14, // ochre
    0xFF2A6FA8, // blue
    0xFF6B2D4F, // plum
    0xFF3F5B2A, // moss
    0xFF8E3B1F, // brick
    0xFF3A4A66, // slate
    0xFF7A1F3D, // wine
  ];

  static const String _c = '#F4EFE2';

  static final List<String Function(String f, String d)> _symbols = [
    // 0 castle
    (f, d) =>
        '<g fill="$_c"><rect x="35" y="38" width="30" height="42"/>'
        '<rect x="33" y="30" width="8" height="10"/>'
        '<rect x="46" y="30" width="8" height="10"/>'
        '<rect x="59" y="30" width="8" height="10"/>'
        '<rect x="22" y="52" width="14" height="28"/>'
        '<rect x="64" y="52" width="14" height="28"/>'
        '<rect x="21" y="46" width="5" height="8"/>'
        '<rect x="31" y="46" width="5" height="8"/>'
        '<rect x="64" y="46" width="5" height="8"/>'
        '<rect x="74" y="46" width="5" height="8"/></g>'
        '<path d="M44 80 V66 A6 6 0 0 1 56 66 V80 Z" fill="$f"/>'
        '<rect x="48.5" y="46" width="3" height="10" fill="$f"/>',
    // 1 eagle
    (f, d) =>
        '<g fill="$_c"><path d="M50 38 L22 30 L28 40 L18 44 L28 50 L24 58 '
        'L50 60 Z"/><path d="M50 38 L78 30 L72 40 L82 44 L72 50 L76 58 '
        'L50 60 Z"/><path d="M44 40 H56 L58 62 L50 76 L42 62 Z"/>'
        '<path d="M42 66 L50 84 L58 66 Z"/><circle cx="50" cy="34" r="6"/>'
        '<path d="M55 33 L63 36 L55 38 Z"/></g>'
        '<circle cx="52" cy="33" r="1.4" fill="$f"/>',
    // 2 stag
    (f, d) =>
        '<g stroke="$_c" stroke-width="4" stroke-linecap="round" fill="none">'
        '<path d="M42 54 L34 38 L28 20"/><path d="M34 38 L22 34"/>'
        '<path d="M37 46 L26 48"/><path d="M58 54 L66 38 L72 20"/>'
        '<path d="M66 38 L78 34"/><path d="M63 46 L74 48"/></g>'
        '<path d="M40 54 H60 L56 80 L50 88 L44 80 Z" fill="$_c"/>'
        '<path d="M40 56 L32 52 L38 62 Z M60 56 L68 52 L62 62 Z" '
        'fill="$_c"/>',
    // 3 church
    (f, d) =>
        '<g fill="$_c"><rect x="40" y="50" width="20" height="30"/>'
        '<path d="M38 50 L50 24 L62 50 Z"/>'
        '<rect x="48.5" y="10" width="3" height="16"/>'
        '<rect x="45" y="14" width="10" height="3"/>'
        '<rect x="24" y="64" width="16" height="16"/>'
        '<rect x="60" y="64" width="16" height="16"/></g>'
        '<path d="M46 80 V66 A4 4 0 0 1 54 66 V80 Z" fill="$f"/>',
    // 4 sloth
    (f, d) =>
        '<rect x="10" y="30" width="80" height="6" rx="3" fill="$_c"/>'
        '<path d="M39 58 Q29 44 35 34 M61 58 Q71 44 65 34" stroke="$_c" '
        'stroke-width="5" fill="none" stroke-linecap="round"/>'
        '<ellipse cx="50" cy="70" rx="15" ry="19" fill="$_c"/>'
        '<circle cx="50" cy="52" r="11" fill="$_c"/>'
        '<ellipse cx="50" cy="52" rx="8" ry="5.5" fill="$d"/>'
        '<circle cx="46.5" cy="52" r="1.6" fill="$_c"/>'
        '<circle cx="53.5" cy="52" r="1.6" fill="$_c"/>'
        '<path d="M48 57 Q50 58.5 52 57" stroke="$_c" stroke-width="1.2" '
        'fill="none"/>',
    // 5 lighthouse
    (f, d) =>
        '<g fill="$_c" opacity=".35"><polygon points="43,31 12,22 12,42"/>'
        '<polygon points="57,31 88,22 88,42"/></g>'
        '<polygon points="40,92 60,92 56,40 44,40" fill="$_c"/>'
        '<g fill="$f"><polygon points="43.04,52 56.96,52 57.6,60 42.4,60"/>'
        '<polygon points="41.6,70 58.4,70 59.04,78 40.96,78"/></g>'
        '<rect x="43" y="30" width="14" height="10" fill="$_c"/>'
        '<polygon points="41,30 50,21 59,30" fill="$_c"/>'
        '<rect x="36" y="40" width="28" height="3" fill="$_c"/>',
    // 6 windmill
    (f, d) =>
        '<polygon points="36,90 64,90 58,50 42,50" fill="$_c"/>'
        '<polygon points="40,50 50,40 60,50" fill="$_c"/>'
        '<path d="M45 90 V78 A5 5 0 0 1 55 78 V90 Z" fill="$f"/>'
        '<g transform="rotate(25 50 46)" fill="$_c" stroke="$_c">'
        '<g stroke-width="3"><line x1="50" y1="46" x2="50" y2="14"/>'
        '<line x1="50" y1="46" x2="50" y2="78"/>'
        '<line x1="50" y1="46" x2="18" y2="46"/>'
        '<line x1="50" y1="46" x2="82" y2="46"/></g>'
        '<rect x="52" y="14" width="9" height="16" stroke="none"/>'
        '<rect x="39" y="62" width="9" height="16" stroke="none"/>'
        '<rect x="20" y="37" width="16" height="9" stroke="none"/>'
        '<rect x="64" y="46" width="16" height="9" stroke="none"/></g>'
        '<circle cx="50" cy="46" r="3.5" fill="$f"/>',
    // 7 owl
    (f, d) =>
        '<polygon points="30,42 33,22 46,34" fill="$_c"/>'
        '<polygon points="70,42 67,22 54,34" fill="$_c"/>'
        '<ellipse cx="50" cy="62" rx="23" ry="30" fill="$_c"/>'
        '<circle cx="40" cy="52" r="10" fill="$f"/>'
        '<circle cx="60" cy="52" r="10" fill="$f"/>'
        '<circle cx="40" cy="52" r="4.5" fill="$_c"/>'
        '<circle cx="60" cy="52" r="4.5" fill="$_c"/>'
        '<polygon points="46,60 54,60 50,70" fill="$f"/>'
        '<path d="M38 76 Q50 84 62 76 M40 85 Q50 92 60 85" stroke="$f" '
        'stroke-width="2.5" fill="none" stroke-linecap="round"/>',
    // 8 bridge
    (f, d) =>
        '<rect x="12" y="46" width="76" height="7" fill="$_c"/>'
        '<rect x="12" y="53" width="76" height="34" fill="$_c"/>'
        '<g fill="$f"><path d="M20 87 V75 A9 9 0 0 1 38 75 V87 Z"/>'
        '<path d="M41 87 V75 A9 9 0 0 1 59 75 V87 Z"/>'
        '<path d="M62 87 V75 A9 9 0 0 1 80 75 V87 Z"/></g>'
        '<g fill="$_c"><rect x="12" y="38" width="4" height="8"/>'
        '<rect x="84" y="38" width="4" height="8"/>'
        '<rect x="30" y="40" width="3" height="6"/>'
        '<rect x="48" y="40" width="3" height="6"/>'
        '<rect x="67" y="40" width="3" height="6"/></g>',
    // 9 penguin
    (f, d) =>
        '<ellipse cx="50" cy="66" rx="21" ry="32" fill="$d"/>'
        '<circle cx="50" cy="38" r="13" fill="$d"/>'
        '<ellipse cx="50" cy="70" rx="12" ry="23" fill="$_c"/>'
        '<ellipse cx="27" cy="64" rx="5" ry="16" fill="$d" '
        'transform="rotate(12 27 64)"/>'
        '<ellipse cx="73" cy="64" rx="5" ry="16" fill="$d" '
        'transform="rotate(-12 73 64)"/>'
        '<polygon points="45,40 55,40 50,49" fill="$_c"/>'
        '<circle cx="44.5" cy="35" r="1.8" fill="$_c"/>'
        '<circle cx="55.5" cy="35" r="1.8" fill="$_c"/>'
        '<ellipse cx="42" cy="96" rx="7" ry="3" fill="$_c"/>'
        '<ellipse cx="58" cy="96" rx="7" ry="3" fill="$_c"/>',
  ];
}

/// The crest of a club, drawn from its id.
class ClubCrest extends StatelessWidget {
  const ClubCrest({required this.clubId, this.size = 56, super.key});

  final int clubId;

  /// Height of the crest; the width follows.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      CrestSpec.forClub(clubId).toSvg(),
      height: size,
      width: size * 100 / 110,
    );
  }
}
