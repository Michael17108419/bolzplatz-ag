import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';
import 'logo_svg.dart';

/// Common frame of all screens except the main menu: centred content with a
/// maximum width, airy margins, and Esc to go back.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    required this.title,
    required this.child,
    this.maxWidth = 720,
    this.padding = const EdgeInsets.all(Tokens.gapL),
    this.extraBindings = const {},
    super.key,
  });

  final String title;
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  /// More keyboard shortcuts besides Esc (for example the desk numbers).
  final Map<ShortcutActivator, VoidCallback> extraBindings;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
        ...extraBindings,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            automaticallyImplyLeading: false,
            leadingWidth: 130,
            leading: Padding(
              padding: const EdgeInsets.only(left: Tokens.gapL),
              child: SvgPicture.string(
                bolzplatzLogoSvg,
                key: const ValueKey('app-logo'),
                alignment: Alignment.centerLeft,
                semanticsLabel: 'Bolzplatz AG',
              ),
            ),
            title: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
