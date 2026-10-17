import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';
import 'adaptive.dart';
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
    this.showBack = true,
    super.key,
  });

  final String title;
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  /// More keyboard shortcuts besides Esc (for example the desk numbers).
  final Map<ShortcutActivator, VoidCallback> extraBindings;

  /// Phone: an arrow top left instead of the logo, if there is a way back.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final back = showBack && isNarrow(context) && Navigator.canPop(context);
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
            toolbarHeight: compact ? 56 : 72,
            automaticallyImplyLeading: false,
            leadingWidth: back ? 64 : (compact ? 96 : 130),
            leading: back
                ? IconButton(
                    key: const ValueKey('frame-back'),
                    iconSize: 28,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  )
                : Padding(
              padding: EdgeInsets.only(
                left: compact ? Tokens.gapM : Tokens.gapL,
              ),
              child: SvgPicture.string(
                bolzplatzLogoSvg,
                key: const ValueKey('app-logo'),
                alignment: Alignment.centerLeft,
                semanticsLabel: 'Bolzplatz AG',
              ),
            ),
            title: Text(
              title,
              style: compact
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: compact
                    ? padding.copyWith(
                        left: Tokens.gapM,
                        right: Tokens.gapM,
                        top: Tokens.gapS,
                        bottom: Tokens.gapS,
                      )
                    : padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
