import 'package:flutter/material.dart';

/// Screens narrower than this (a phone held upright) get the one-column
/// layout; wider ones keep the two columns of the desktop.
const double narrowWidth = 640;

/// True on a phone held upright.
bool isNarrow(BuildContext context) =>
    MediaQuery.sizeOf(context).width < narrowWidth;

/// True when the screen is small in either direction (a phone upright or on
/// its side): the frame then uses less room for itself.
bool isCompact(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width < narrowWidth || size.height < 500;
}
