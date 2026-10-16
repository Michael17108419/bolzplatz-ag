#!/usr/bin/env python3
"""Builds the office scene (stage 1, "Provisorium") from SVG layers.

Usage:
  python3 tool/office/build_office.py dart      # writes lib/ui/office_svgs.dart
  python3 tool/office/build_office.py preview   # writes tool/office/preview.html

One layer per desk item, so a later stage only swaps that layer. The club
colours are the placeholders {{club}}, {{clubDark}} and {{clubLight}}. The
layers use only what flutter_svg draws (no text, no filters, no CSS).
"""
import pathlib
import sys

O = '#2B1B12'  # outline
W, H = 1500, 1300
CORE_H = 900  # the picture proper; below it the floor goes on

# Where each layer sits in the 1500 x 900 room: (scale, shift x, shift y)
# applied to the layer's own drawing coordinates. The room has three views
# (zones) of 500 units each; every desk item lies whole in one of them.
PLACE = {
    'tactics': (1.0, -50.0, 0.0),
    'transfers': (0.9, -17.0, 14.0),
    'press': (1.0, 20.0, 0.0),
    'grounds': (1.0, -22.0, 0.0),
    'calendar': (1.4, -302.0, -300.8),
    'stats': (0.86, 116.2, 6.8),
    'door': (1.0, -100.0, 0.0),
    'finance': (0.8, 266.0, 155.0),
    'frame': (1.0, 22.0, 0.0),
}


def place(name, s):
    if name not in PLACE:
        return s
    k, tx, ty = PLACE[name]
    g = '<g transform="translate(%g %g) scale(%g)">' % (tx, ty, k)
    if '</defs>' in s:
        s = s.replace('</defs>', '</defs>' + g, 1)
    else:
        i = s.index('>') + 1
        s = s[:i] + g + s[i:]
    return s[:-len('</svg>')] + '</g></svg>'


def svg(body, defs=''):
    d = '<defs>' + defs + '</defs>' if defs else ''
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d">'
            % (W, H)) + d + body + '</svg>'


def lg(id_, stops, x1=0, y1=0, x2=0, y2=1):
    s = ''.join('<stop offset="%s" stop-color="%s"%s/>' % (
        o, c, (' stop-opacity="%s"' % a) if a is not None else '')
        for o, c, a in stops)
    return ('<linearGradient id="%s" x1="%s" y1="%s" x2="%s" y2="%s">%s'
            '</linearGradient>' % (id_, x1, y1, x2, y2, s))


def rg(id_, cx, cy, r, stops):
    s = ''.join('<stop offset="%s" stop-color="%s" stop-opacity="%s"/>' % st
                for st in stops)
    return ('<radialGradient id="%s" cx="%s" cy="%s" r="%s" '
            'gradientUnits="userSpaceOnUse">%s</radialGradient>'
            % (id_, cx, cy, r, s))


def poly(points, fill, sw=3, extra=''):
    pts = ' '.join('%g,%g' % p for p in points)
    return ('<polygon points="%s" fill="%s" stroke="%s" stroke-width="%g" '
            'stroke-linejoin="round" %s/>' % (pts, fill, O, sw, extra))


def rect(x, y, w, h, fill, sw=3, rx=0, extra=''):
    stroke = ('stroke="%s" stroke-width="%g" stroke-linejoin="round"'
              % (O, sw)) if sw else ''
    return ('<rect x="%g" y="%g" width="%g" height="%g" rx="%g" fill="%s" '
            '%s %s/>' % (x, y, w, h, rx, fill, stroke, extra))


def line(x1, y1, x2, y2, color=O, sw=2, op=1, extra=''):
    return ('<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="%s" '
            'stroke-width="%g" stroke-opacity="%g" stroke-linecap="round" '
            '%s/>' % (x1, y1, x2, y2, color, sw, op, extra))


def circle(cx, cy, r, fill, sw=0, extra=''):
    stroke = ('stroke="%s" stroke-width="%g"' % (O, sw)) if sw else ''
    return ('<circle cx="%g" cy="%g" r="%g" fill="%s" %s %s/>'
            % (cx, cy, r, fill, stroke, extra))


def ell(cx, cy, rx, ry, fill, op=1, extra=''):
    return ('<ellipse cx="%g" cy="%g" rx="%g" ry="%g" fill="%s" '
            'fill-opacity="%g" %s/>' % (cx, cy, rx, ry, fill, op, extra))


def path(d, fill='none', stroke=O, sw=3, op=1, extra=''):
    return ('<path d="%s" fill="%s" stroke="%s" stroke-width="%g" '
            'stroke-opacity="%g" stroke-linecap="round" '
            'stroke-linejoin="round" %s/>' % (d, fill, stroke, sw, op, extra))


def scribble(x, y, w, n, gap=8, color='#6b5a48', op=.8, sw=2):
    out = ''
    for i in range(n):
        ww = w * (0.55 + 0.45 * ((i * 37) % 10) / 10)
        out += line(x, y + i * gap, x + ww, y + i * gap, color, sw, op)
    return out


# --------------------------------------------------------------------- room
def room():
    defs = (
        lg('wall', [(0, '#E0D2AB', None), (1, '#C2B28A', None)])
        + lg('dado', [(0, '{{clubLight}}', None), (1, '{{club}}', None)])
        + lg('floor', [(0, '#5C412E', None), (1, '#2F2118', None)])
        + rg('vig', 750, 380, 940, [(0.5, '#1a0f08', 0), (1, '#1a0f08', .5)])
        + rg('glow', 750, 84, 150, [(0, '#FFE9A0', .55), (1, '#FFE9A0', 0)])
    )
    b = rect(0, 0, W, 620, 'url(#wall)', 0)
    for x in range(0, W, 80):
        b += rect(x, 0, 40, 466, '#ffffff', 0, 0, 'fill-opacity="0.04"')
    # peeled plaster with bricks
    b += '<g transform="translate(314 0)">'
    b += path('M26 36 Q70 20 126 30 L152 74 Q150 120 106 146 L48 128 '
              'Q20 90 26 36Z', '#BFAE86', '#9C8A62', 2, 1)
    for (x, y) in [(52, 56), (86, 56), (68, 74), (52, 92), (86, 92),
                   (104, 110)]:
        b += rect(x, y, 30, 14, '#9A4B34', 1, 1, 'fill-opacity="0.85"')
    b += '</g>'
    b += ell(1330, 96, 96, 44, '#7a5a30', .10)
    b += ell(1360, 120, 60, 26, '#7a5a30', .10)
    # club coloured dado
    b += rect(0, 466, W, 134, 'url(#dado)', 0)
    b += rect(0, 460, W, 9, '#F4EFE2', 0)
    b += rect(0, 469, W, 4, '#000000', 0, 0, 'fill-opacity="0.25"')
    for x in range(40, W, 120):
        b += rect(x, 490, 70, 90, '#000000', 0, 6, 'fill-opacity="0.07"')
    b += rect(0, 592, W, 24, '#3B281B', 4)
    # floor with planks
    b += rect(0, 616, W, H - 616, 'url(#floor)', 0)
    for i in range(1, 9):
        y = 616 + i * i * 9
        b += line(0, y, W, y, '#1a0f08', 2, .35)
    for x in range(-600, 2200, 150):
        b += line(750 + (x - 750) * .3, 616, x, H, '#1a0f08', 2, .28)
    # rug in the club colour (mostly hidden by the desk)
    b += path('M70 748 Q750 646 1430 748 L1500 %d L0 %d Z' % (H, H), '{{club}}',
              '#F4EFE2', 6)
    b += path('M130 782 Q750 690 1370 782', 'none', '{{clubLight}}', 5, .8)
    b += path('M170 830 Q750 748 1330 830', 'none', '#F4EFE2', 3, .55,
              'stroke-dasharray="14 10"')
    # bare bulb on a cord
    b += ell(750, 84, 150, 150, 'url(#glow)', 1)
    b += line(750, 0, 750, 62, O, 3)
    b += rect(741, 58, 18, 14, '#6b6b6b', 2, 2)
    b += circle(750, 86, 17, '#FFE9A0', 3)
    b += path('M743 90 q7 -10 14 0', 'none', '#C79A2A', 2)
    # mouse hole
    b += path('M1394 592 q0 -28 22 -28 q22 0 22 28 z', '#140b06', O, 3)
    b += circle(1405, 586, 2, '#ffffff')
    b += circle(1428, 586, 2, '#ffffff')
    b += rect(0, 0, W, H, 'url(#vig)', 0)
    return svg(b, defs)


# -------------------------------------------------------------------- desk
def desk():
    defs = (
        lg('dtop', [(0, '#B07040', None), (1, '#8C5631', None)])
        + lg('dfront', [(0, '#7C4A2A', None), (1, '#583219', None)])
        + lg('dknee', [(0, '#1f130b', None), (1, '#0d0704', None)])
    )
    b = poly([(330, 640), (1270, 640), (1350, 790), (250, 790)],
             'url(#dtop)', 4)
    for k in range(1, 9):
        u = k / 9.0
        b += line(330 + 940 * u, 642, 250 + 1100 * u, 788, '#5b3519', 2, .22)
    b += poly([(330, 640), (800, 640), (700, 790), (250, 790)],
              '#ffffff', 0, 'fill-opacity="0.07"')
    b += ell(1120, 700, 28, 9, '#1d2a4d', .5)  # ink stain
    b += ell(1120, 700, 15, 4, '#1d2a4d', .5)
    b += circle(470, 662, 7, '#3a1d0c', 0, 'fill-opacity="0.6"')  # burn mark
    b += path('M300 765 Q420 758 520 778', 'none', '#4a2a12', 2, .5)  # crack
    b += poly([(250, 790), (1350, 790), (1350, 812), (250, 812)], '#6A3E22', 4)
    b += ell(800, 962, 590, 16, '#000000', .35)  # shadow on the floor
    b += rect(262, 812, 1076, 148, 'url(#dfront)', 4)
    b += rect(610, 822, 370, 138, 'url(#dknee)', 3)
    b += rect(262, 944, 1076, 16, '#3F2412', 3)  # plinth
    # left drawer unit
    for (y, h, open_) in [(824, 36, True), (864, 34, False)]:
        b += rect(278, y, 312, h, '#7A4727', 3, 2)
        b += rect(286, y + 7, 296, h - 14, '#000000', 0, 2,
                  'fill-opacity="0.15"')
        b += rect(398, y + h / 2 - 5, 70, 9, '#D2A24C', 2, 4)
    b += rect(278, 818, 312, 8, '#140b06', 0)  # first drawer stands open
    b += rect(330, 811, 30, 9, '#E8D9A8', 1.5, 1)  # folder tab peeking out
    # right drawer unit: lower drawer (the upper one is its own layer)
    b += rect(1005, 868, 310, 30, '#7A4727', 3, 2)
    b += rect(1013, 875, 294, 16, '#000000', 0, 2, 'fill-opacity="0.15"')
    b += rect(1135, 877, 50, 9, '#D2A24C', 2, 4)
    return svg(b, defs)


# ----------------------------------------------------------------- objects
def files():  # Spielerakten
    defs = (lg('card', [(0, '#CFA168', None), (1, '#A9794A', None)])
            + lg('card2', [(0, '#C99A60', None), (1, '#9D6F40', None)]))
    b = ell(185, 694, 160, 14, '#000000', .3)
    b += rect(60, 650, 250, 42, '#8A6A44', 4)
    for x in (100, 180, 260):
        b += line(x, 650, x, 692, O, 3, .6)
    # bottom box
    b += rect(52, 540, 256, 112, 'url(#card)', 4)
    b += rect(158, 540, 34, 112, '#E6C991', 0, 0, 'fill-opacity="0.55"')
    b += rect(200, 566, 84, 46, '#F4EFE2', 3, 2)
    b += scribble(208, 578, 66, 4, 9)
    b += path('M70 600 l0 30 m-8 -8 l8 8 l8 -8', 'none', O, 4)  # up arrows
    # middle box, open on top, papers poking out
    g = '<g transform="rotate(-3 185 490)">'
    g += rect(80, 440, 212, 104, 'url(#card2)', 4)
    g += poly([(80, 440), (292, 440), (310, 418), (66, 418)], '#B98B55', 3)
    for i, (x, h, rot) in enumerate([(100, 50, -8), (150, 58, 5),
                                       (205, 46, 12), (240, 54, -3)]):
        g += ('<g transform="rotate(%d %d 440)">' % (rot, x))
    # (papers are drawn explicitly below for readability)
    g = '<g transform="rotate(-3 185 490)">'
    g += rect(80, 440, 212, 104, 'url(#card2)', 4)
    g += rect(86, 392, 52, 56, '#F7F3E6', 2, 0, 'transform="rotate(-9 112 420)"')
    g += rect(142, 384, 56, 62, '#EFEBDD', 2, 0, 'transform="rotate(6 170 415)"')
    g += rect(206, 396, 50, 52, '#F7F3E6', 2, 0, 'transform="rotate(14 230 420)"')
    g += rect(80, 440, 212, 104, 'url(#card2)', 4)
    g += rect(86, 446, 200, 12, '#000000', 0, 0, 'fill-opacity="0.12"')
    g += rect(92, 470, 70, 36, '#F4EFE2', 3, 2)
    g += scribble(98, 482, 58, 3, 9)
    g += '</g>'
    b += g
    # binders on top of the middle box
    for (x, c, rot) in [(96, '#B8352B', -10), (116, '#2F5D9E', -4),
                        (136, '#3C8A4E', 3)]:
        b += rect(x, 372, 18, 64, c, 3, 2,
                  'transform="rotate(%d %d 436)"' % (rot, x + 9))
        b += rect(x + 5, 380, 8, 20, '#F4EFE2', 1.5, 1,
                  'transform="rotate(%d %d 436)"' % (rot, x + 9))
    # small top box with a sad plant in a mug
    g = '<g transform="rotate(4 228 408)">'
    g += rect(166, 372, 124, 72, 'url(#card)', 4)
    g += '</g>'
    b += g
    b += rect(210, 338, 34, 36, '#F4EFE2', 3, 6)
    b += path('M244 346 q14 4 0 18', 'none', O, 3)
    b += path('M226 338 q-6 -22 -2 -36', 'none', '#6A4A22', 3)
    b += path('M228 338 q8 -16 18 -22', 'none', '#6A4A22', 3)
    b += path('M222 304 q-14 -4 -16 8 q12 2 16 -8z', '#8a6a2a', '#5a4418', 2)
    b += path('M246 316 q12 -4 14 6 q-12 4 -14 -6z', '#8a6a2a', '#5a4418', 2)
    return svg(b, defs)


def tactics():  # Taktiktafel
    defs = (lg('board', [(0, '#35523F', None), (1, '#1F3328', None)])
            + lg('frame', [(0, '#9B6A3C', None), (1, '#7A4E2A', None)]))
    c = '#F4F1E8'
    b = '<g transform="rotate(-1.2 215 220)">'
    b += line(215, 96, 120, 116, O, 2.5) + line(215, 96, 312, 116, O, 2.5)
    b += circle(215, 98, 5, '#5a5a5a', 2)
    b += rect(70, 110, 290, 220, 'url(#frame)', 5, 6)
    b += rect(84, 124, 262, 188, 'url(#board)', 3)
    for (x, y, rx, ry) in [(140, 160, 40, 10), (250, 270, 50, 12),
                           (190, 220, 60, 14), (300, 180, 24, 8)]:
        b += ell(x, y, rx, ry, '#ffffff', .07)
    # chalk pitch
    b += rect(104, 142, 222, 150, 'none', 2.5, 0,
              'stroke="%s" stroke-opacity="0.9"' % c).replace(
        'stroke="%s" stroke-width="2.5" stroke-linejoin="round"' % O, '')
    b += path('M104 142 H326 V292 H104 Z', 'none', c, 2.5, .9)
    b += line(215, 142, 215, 292, c, 2.5, .9)
    b += circle(215, 217, 26, 'none', 0, 'stroke="%s" stroke-width="2.5" '
                'stroke-opacity="0.9"' % c)
    b += path('M104 180 H146 V254 H104', 'none', c, 2.5, .9)
    b += path('M326 180 H284 V254 H326', 'none', c, 2.5, .9)
    # crosses (own team), circles (opponent), dashed arrows
    for (x, y) in [(150, 170), (170, 215), (155, 262), (240, 150), (200, 198)]:
        b += path('M%d %d l12 12 m0 -12 l-12 12' % (x, y), 'none', c, 3, .95)
    for (x, y) in [(270, 175), (255, 222), (290, 262), (236, 248)]:
        b += circle(x, y, 7, 'none', 0, 'stroke="#FFC400" stroke-width="3"')
    b += path('M176 232 Q206 200 250 214', 'none', '#FFC400', 3, 1,
              'stroke-dasharray="7 6"')
    b += poly([(252, 206), (262, 216), (248, 222)], '#FFC400', 0)
    b += path('M162 188 Q200 160 236 166', 'none', c, 2.5, .8,
              'stroke-dasharray="6 6"')
    # tray with chalk and sponge
    b += rect(84, 312, 262, 14, '#6B4424', 3)
    b += rect(116, 305, 32, 7, '#F4F1E8', 1.5, 2)
    b += rect(280, 300, 36, 12, '#E6C94F', 2, 3)
    b += '</g>'
    return svg(b, defs)


def transfers():  # Weltkarte mit Stecknadeln
    b = '<g transform="rotate(2 480 230)">'
    b += rect(402, 152, 156, 156, '#EEE2BF', 3)
    b += rect(410, 162, 140, 136, '#A9C7C2', 0, 0, 'fill-opacity="0.6"')
    green = '#8FA66B'
    b += path('M430 190 q20 -14 40 -4 q10 20 -6 34 q-22 8 -34 -4 z',
              green, '#5F7347', 2)
    b += path('M480 232 q22 -6 36 10 q6 22 -14 36 q-22 4 -28 -14 z',
              '#B39A5A', '#7a6738', 2)
    b += path('M494 176 q24 -10 40 6 q-4 18 -22 22 q-18 -2 -18 -28 z',
              green, '#5F7347', 2)
    b += path('M430 262 q16 -6 28 6 q-6 14 -24 12 z', '#B39A5A', '#7a6738', 2)
    pins = [(445, 205), (500, 200), (516, 256), (440, 270), (530, 215)]
    b += '<polyline points="%s" fill="none" stroke="#C0392B" stroke-width="2" ' \
         'stroke-opacity="0.9"/>' % ' '.join('%d,%d' % p for p in pins)
    for i, (x, y) in enumerate(pins):
        col = ['#E03131', '#FFC400', '#2F7DE1', '#E03131', '#2ED47A'][i]
        b += circle(x, y, 6, col, 2) + circle(x - 2, y - 2, 1.8, '#ffffff')
    b += rect(392, 146, 34, 13, '#FFD84A', 1, 0,
              'fill-opacity="0.8" transform="rotate(-32 409 152)"')
    b += rect(534, 300, 34, 13, '#FFD84A', 1, 0,
              'fill-opacity="0.8" transform="rotate(-32 551 306)"')
    b += poly([(558, 308), (528, 308), (558, 278)], '#CDBE95', 2)
    b += '</g>'
    return svg(b)


def grounds():  # Fenster zum Hinterhof
    defs = (lg('sky', [(0, '#9CCFE8', None), (1, '#F2EBCB', None)])
            + lg('grass', [(0, '#52A85C', None), (1, '#2E7A3E', None)]))
    b = rect(630, 110, 340, 210, 'url(#sky)', 0)
    for (x, y, rx) in [(700, 150, 34), (738, 144, 26), (722, 160, 38),
                       (900, 135, 28), (930, 142, 22)]:
        b += ell(x, y, rx, 12, '#ffffff', .9)
    b += path('M630 250 Q700 214 780 244 Q860 218 970 256 L970 320 L630 320Z',
              '#5E8F54', 'none', 0)
    b += rect(630, 270, 340, 50, 'url(#grass)', 0)
    for (x, y, rx) in [(680, 300, 22), (760, 288, 16), (880, 306, 24),
                       (940, 292, 14)]:
        b += ell(x, y, rx, 6, '#2c6e38', .6)
    b += ell(720, 296, 14, 6, '#6B4A2E', .9) + ell(912, 280, 10, 5, '#6B4A2E', .9)
    # crooked goal
    b += line(850, 224, 850, 300, '#F4F1E8', 6) + line(930, 228, 930, 300,
                                                      '#F4F1E8', 6)
    b += line(848, 224, 932, 229, '#F4F1E8', 6)
    for k in range(1, 6):
        b += line(850 + k * 13, 228, 850 + k * 13, 298, '#F4F1E8', 1, .35)
    # fence with missing planks
    for i, x in enumerate(range(634, 970, 26)):
        if i in (3, 8):
            continue
        h = 36 if i % 4 else 30
        b += rect(x, 252 + (36 - h), 20, h, '#7A5A3A', 2, 1)
    b += rect(690, 280, 26, 32, '#7d7d7d', 3, 2) + rect(686, 274, 34, 8,
                                                       '#9a9a9a', 3, 2)
    b += circle(776, 304, 8, '#F4F1E8', 2)
    b += path('M772 302 l4 -3 l4 3 l-1 5 h-6 z', O, O, 1)
    # window frame (hole in the middle), muntins, sill
    b += ('<path d="M610 90H990V340H610Z M630 110V320H970V110Z" '
          'fill-rule="evenodd" fill="#E9E1CC" stroke="%s" stroke-width="4" '
          'stroke-linejoin="round"/>' % O)
    b += rect(794, 110, 12, 210, '#E9E1CC', 3) + rect(630, 208, 340, 12,
                                                     '#E9E1CC', 3)
    for (x, y) in [(618, 104), (962, 98), (640, 330), (940, 334)]:
        b += poly([(x, y), (x + 14, y + 4), (x + 8, y + 14)], '#9A8F6D', 0,
                  'fill-opacity="0.7"')
    b += poly([(594, 340), (1006, 340), (1022, 364), (578, 364)], '#D8CFB4', 4)
    b += poly([(640, 115), (710, 115), (654, 204), (640, 204)], '#ffffff', 0,
              'fill-opacity="0.18"')
    b += '<polyline points="900,112 928,168 904,214 940,262" fill="none" ' \
         'stroke="#ffffff" stroke-width="1.6" stroke-opacity="0.65"/>'
    b += rect(906, 160, 30, 12, '#FFD84A', 0, 0,
              'fill-opacity="0.7" transform="rotate(-20 920 166)"')
    for r in (24, 40, 56):
        b += path('M%d 110 A%d %d 0 0 0 630 %d' % (630 + r, r, r, 110 + r),
                  'none', '#ffffff', 1.2, .5)
    return svg(b, defs)


def stats():  # Statistik und Rueckblick: Poster plus Pokalbretter
    b = '<g transform="rotate(-1.5 1100 230)">'
    b += rect(1040, 130, 120, 200, '#F6F1E0', 3)
    b += rect(1048, 140, 104, 36, '{{club}}', 2)
    b += rect(1056, 150, 60, 6, '#F4EFE2', 0, 3) + rect(1056, 162, 40, 5,
                                                        '#F4EFE2', 0, 2)
    base = 290
    for (x, h, c) in [(1054, 60, '#FF7A1A'), (1076, 90, '#2ED47A'),
                      (1098, 45, '#FFC400'), (1120, 110, '#2F5D9E')]:
        b += rect(x, base - h, 18, h, c, 2)
    b += line(1050, base, 1152, base, O, 2.5)
    b += circle(1132, 206, 16, '#FF7A1A', 2)
    b += path('M1132 206 V190 A16 16 0 0 1 1146 214 Z', '#FFC400', O, 2)
    b += scribble(1052, 302, 92, 3, 9)
    b += circle(1100, 134, 5, '#E03131', 2)
    b += '</g>'
    # trophy boards (the cups themselves are drawn by the app)
    b += rect(1186, 236, 218, 12, '#8A5A32', 3)
    b += poly([(1202, 248), (1218, 248), (1202, 270)], '#6B4424', 3)
    b += poly([(1372, 248), (1388, 248), (1388, 270)], '#6B4424', 3)
    b += ('<g transform="rotate(1.8 1295 342)">'
          + rect(1186, 336, 218, 12, '#8A5A32', 3)
          + poly([(1202, 348), (1218, 348), (1202, 370)], '#6B4424', 3)
          + '</g>')
    b += ('<g transform="rotate(3 1360 175)">' + rect(1328, 148, 66, 54,
                                                      '#FFE680', 2)
          + scribble(1336, 162, 50, 4, 9, '#7a6a2a') + circle(1361, 150, 4,
                                                              '#E03131', 1.5)
          + '</g>')
    return svg(b)


def door():  # Weiter
    defs = (lg('sky2', [(0, '#9CCFE8', None), (1, '#F2EBCB', None)])
            + lg('leaf', [(0, '#A87347', None), (1, '#7C4F2B', None)])
            + lg('light', [(0, '#FFF3B0', .35), (1, '#FFF3B0', 0)]))
    b = poly([(1448, 654), (1594, 654), (1600, 740), (1380, 740)],
             'url(#light)', 0)
    b += rect(1436, 106, 158, 548, '#4A3020', 4)
    b += rect(1448, 118, 134, 530, 'url(#sky2)', 3)
    b += rect(1448, 470, 134, 178, '#3F9A4C', 0)
    b += ell(1560, 500, 30, 8, '#2c6e38', .7)
    b += poly([(1448, 118), (1514, 150), (1514, 626), (1448, 648)],
              'url(#leaf)', 4)
    b += poly([(1458, 160), (1504, 180), (1504, 330), (1458, 322)], '#000000',
              1, 'fill-opacity="0.14"')
    b += poly([(1458, 360), (1504, 366), (1504, 600), (1458, 614)], '#000000',
              1, 'fill-opacity="0.14"')
    b += circle(1498, 400, 7, '#D2A24C', 2.5)
    b += rect(1490, 372, 6, 56, '#B88A3A', 2, 2)
    # arrow board above the door
    b += rect(1462, 56, 108, 40, '#2C7A4B', 4, 4)
    b += poly([(1480, 70), (1530, 70), (1530, 62), (1552, 76), (1530, 90),
               (1530, 82), (1480, 82)], '#F4F1E8', 2)
    return svg(b, defs)


def drawer():  # Spielstaende: obere Schublade
    defs = lg('dr', [(0, '#8D5430', None), (1, '#734424', None)])
    b = rect(1005, 818, 310, 8, '#140b06', 0)
    b += rect(1030, 811, 28, 9, '#FFC400', 1.5, 1)
    b += rect(1070, 813, 24, 7, '#E03131', 1.5, 1)
    b += rect(1005, 826, 310, 40, 'url(#dr)', 4, 3)
    b += rect(1015, 833, 290, 26, '#000000', 0, 2, 'fill-opacity="0.15"')
    b += rect(1135, 838, 50, 10, '#D2A24C', 2, 5)
    b += rect(1028, 835, 58, 18, '#F4EFE2', 2, 1,
              'transform="rotate(-4 1057 844)"')
    b += scribble(1034, 841, 44, 2, 7)
    return svg(b, defs)


def mail():  # Post: Pappkorb mit Zetteln
    defs = lg('box', [(0, '#CFA168', None), (1, '#A67744', None)])
    b = ell(374, 736, 90, 8, '#000000', .25)
    b += poly([(310, 640), (438, 640), (452, 668), (296, 668)], '#4D3720', 3)
    for (x, y, w, h, r) in [(322, 584, 60, 82, -8), (352, 572, 64, 86, 6),
                            (384, 594, 56, 72, 14)]:
        b += rect(x, y, w, h, '#F7F3E6', 2.5, 0,
                  'transform="rotate(%d %d %d)"' % (r, x + w / 2, y + h))
        b += ('<g transform="rotate(%d %d %d)">' % (r, x + w / 2, y + h)
              + scribble(x + 8, y + 12, w - 18, 5, 9, '#8a7a68', .8, 1.6)
              + '</g>')
    b += circle(396, 612, 12, 'none', 0, 'stroke="#C0392B" stroke-width="4" '
                'transform="rotate(14 396 612)"')
    b += rect(338, 556, 28, 28, '#FFE066', 2, 0, 'transform="rotate(-10 352 570)"')
    b += path('M420 600 q10 -10 18 -2 l-14 22', 'none', '#7a7a7a', 3)
    b += rect(296, 668, 156, 66, 'url(#box)', 4)
    b += rect(358, 668, 30, 66, '#E6C991', 0, 0, 'fill-opacity="0.5"')
    b += rect(318, 688, 52, 28, '#F4EFE2', 2.5, 2)
    b += scribble(324, 698, 40, 3, 8)
    return svg(b, defs)


def press():  # Presse: zerknitterte Zeitung
    A, B, C, D = (505, 745), (690, 772), (745, 702), (575, 695)

    def P(u, v):
        return (A[0] + u * (B[0] - A[0]) + v * (D[0] - A[0]),
                A[1] + u * (B[1] - A[1]) + v * (D[1] - A[1]))

    def Q(u0, v0, u1, v1, fill, sw=0):
        return poly([P(u0, v0), P(u1, v0), P(u1, v1), P(u0, v1)], fill, sw)

    b = poly([(A[0] + 6, A[1] + 8), (B[0] + 6, B[1] + 8), (C[0] + 6, C[1] + 8),
              (D[0] + 6, D[1] + 8)], '#000000', 0, 'fill-opacity="0.2"')
    b += poly([A, B, C, D], '#EDEAE0', 3)
    b += Q(.05, .74, .95, .94, '#2B2B2B')
    b += Q(.52, .74, .95, .94, '#FF7A1A')
    b += Q(.05, .28, .42, .66, '#9A9A92')
    for i in range(6):
        v = .62 - i * .06
        b += poly([P(.47, v), P(.95, v), P(.95, v - .02), P(.47, v - .02)],
                  '#6b6b66', 0)
    for i in range(3):
        v = .22 - i * .06
        b += poly([P(.05, v), P(.42, v), P(.42, v - .02), P(.05, v - .02)],
                  '#6b6b66', 0)
    for i in range(3):
        v = .22 - i * .06
        b += poly([P(.47, v), P(.95, v), P(.95, v - .02), P(.47, v - .02)],
                  '#6b6b66', 0)
    b += poly([P(.5, 0), P(.52, 0), P(.52, 1), P(.5, 1)], '#000000', 0,
              'fill-opacity="0.10"')
    x, y = P(.8, .1)
    b += circle(x, y + 4, 18, 'none', 0, 'stroke="#7a4a22" stroke-width="3" '
                'stroke-opacity="0.55"')
    b += poly([P(.9, 1), P(1, 1), P(1, .88)], '#D8D4C6', 2)
    return svg(b)


def calendar():  # Abreissblock
    b = ell(836, 738, 50, 6, '#000000', .25)
    b += rect(795, 628, 84, 104, '#B28350', 4, 2)
    b += rect(802, 646, 70, 76, '#FBF8EE', 2)
    b += rect(802, 646, 70, 24, '#D9362B', 2)
    b += circle(818, 646, 5, '#6b6b6b', 2) + circle(858, 646, 5, '#6b6b6b', 2)
    b += rect(802, 718, 70, 6, '#ffffff', 1.5)
    b += poly([(800, 742), (826, 738), (830, 750), (804, 754)], '#F7F3E6', 2)
    b += circle(886, 744, 8, '#D8D4C6', 2)
    return svg(b)


def finance():  # Zigarrenkiste mit Taschenrechner
    defs = (lg('cbox', [(0, '#A56E3C', None), (1, '#7E4F28', None)])
            + lg('calc', [(0, '#BDBDBD', None), (1, '#8C8C8C', None)]))
    b = ell(1015, 756, 84, 7, '#000000', .25)
    b += poly([(944, 648), (1086, 648), (1092, 678), (938, 678)], '#6B4424', 3)
    b += rect(952, 660, 52, 26, '#7FB77E', 2, 0,
              'transform="rotate(-5 978 673)"')
    b += scribble(958, 668, 40, 2, 7, '#3a6a3a', .8, 1.5)
    b += rect(938, 676, 154, 76, 'url(#cbox)', 4)
    b += rect(972, 688, 86, 42, '#E8D9A8', 2.5, 2)
    b += circle(1015, 709, 15, '#C0392B', 2.5)
    b += circle(1015, 709, 9, 'none', 0, 'stroke="#E7C65A" stroke-width="2.5"')
    b += scribble(980, 736, 70, 1, 8, '#6b5a48')
    for (x, y) in [(1102, 748), (1112, 756), (1096, 760)]:
        b += ell(x, y, 8, 4, '#E7C65A', 1, 'stroke="%s" stroke-width="2"' % O)
    g = '<g transform="rotate(-4 1150 716)">'
    g += rect(1112, 668, 78, 96, 'url(#calc)', 4, 8)
    g += rect(1120, 676, 62, 24, '#A9C6A0', 2.5, 2)
    g += rect(1146, 682, 6, 12, '#1d2a1d', 0) + rect(1158, 682, 6, 12,
                                                    '#1d2a1d', 0)
    g += rect(1168, 682, 6, 12, '#1d2a1d', 0)
    for j in range(4):
        for i in range(4):
            col = '#FF7A1A' if i == 3 else ('#FFC400' if (i, j) == (2, 3)
                                            else '#2D2D2D')
            g += rect(1122 + i * 15, 708 + j * 13, 12, 9, col, 1.5, 2)
    g += '</g>'
    b += g
    b += path('M1130 668 q-8 -26 6 -38 q16 -8 10 20 q-4 12 6 18', 'none', O, 3,
              1)
    b += path('M1134 666 q-6 -22 6 -32', 'none', '#ffffff', 5, .9)
    return svg(b, defs)


def frame():  # the trainer's photo frame (the portrait is drawn by the app)
    b = rect(1214, 604, 64, 86, '#6D4425', 4, 3)
    b += rect(1224, 614, 44, 66, '#E9DFC6', 2)
    b += poly([(1236, 690), (1256, 690), (1262, 704), (1230, 704)], '#4a2a12',
              2)
    return svg(b)


def deco():  # not clickable: mug, paper stack, crest nail
    b = ell(768, 748, 26, 5, '#000000', .25)
    b += rect(750, 700, 36, 46, '#F4EFE2', 3, 6)
    b += path('M786 710 q16 4 0 24', 'none', O, 3.5)
    b += ell(768, 702, 18, 5, '#5A3A22', 1, 'stroke="%s" stroke-width="2"' % O)
    for dx in (-6, 2, 10):
        b += path('M%d 690 q6 -10 0 -18 q-6 -8 2 -16' % (768 + dx), 'none',
                  '#ffffff', 3, .4)
    # stack of papers
    for i, dx in enumerate((0, 4, -3)):
        b += rect(960 + dx, 730 - i * 7, 48, 10, '#F7F3E6', 2.5)
    b += rect(968, 710, 34, 10, '#FFE066', 2)
    # nail and string for the crest
    b += line(800, 366, 772, 396, '#3a2a1a', 2) + line(800, 366, 828, 396,
                                                       '#3a2a1a', 2)
    b += circle(800, 364, 4, '#6b6b6b', 2)
    return svg(b)


LAYERS = [
    ('room', room), ('files', files), ('tactics', tactics),
    ('transfers', transfers), ('grounds', grounds), ('stats', stats),
    ('door', door), ('desk', desk), ('drawer', drawer), ('mail', mail),
    ('press', press), ('calendar', calendar), ('finance', finance),
    ('frame', frame), ('deco', deco),
]

SAMPLE = {'{{club}}': '#A8232D', '{{clubDark}}': '#5C1319',
          '{{clubLight}}': '#D0505A'}


def sample(s):
    for k, v in SAMPLE.items():
        s = s.replace(k, v)
    return s


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else 'preview'
    here = pathlib.Path(__file__).resolve().parent
    app = here.parent.parent
    if mode == 'dart':
        out = ['// GENERATED by tool/office/build_office.py, do not edit.\n',
               '/// The office scene of stage 1 as SVG layers, back to front.\n',
               '/// {{club}}, {{clubDark}} and {{clubLight}} are replaced by '
               'the club colour.\n',
               'const List<(String, String)> officeLayers = [\n']
        for name, fn in LAYERS:
            out.append("  ('%s', r'''%s'''),\n" % (name, place(name, fn())))
        out.append('];\n\n')
        out.append('/// Size of the room picture and where each layer sits in it '
                   '(scale, shift x, shift y).\n')
        out.append('const double officeW = %d;\nconst double officeH = %d;\n'
                   'const double officeCoreH = %d;\n' % (W, H, CORE_H))
        out.append('const Map<String, (double, double, double)> officePlace = '
                   '{\n')
        for k, (s_, x_, y_) in PLACE.items():
            out.append("  '%s': (%g, %g, %g),\n" % (k, s_, x_, y_))
        out.append('};\n')
        (app / 'lib/ui/office_svgs.dart').write_text(''.join(out))
        print('wrote lib/ui/office_svgs.dart')
    else:
        html = ['<html><body style="margin:0;background:#000">'
                '<div style="position:relative;width:1500px;height:900px">']
        for name, fn in LAYERS:
            html.append('<div style="position:absolute;inset:0">%s</div>'
                        % sample(place(name, fn())))
        html.append('</div></body></html>')
        (here / 'preview.html').write_text(''.join(html))
        print('wrote preview.html')


if __name__ == '__main__':
    main()
