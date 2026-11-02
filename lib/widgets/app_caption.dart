import 'package:flauncher/models/app_card_style.dart';
import 'package:flutter/material.dart';

/// The app name drawn with the user's [AppCaptionStyle], below or on top of an app card.
class AppCaption extends StatelessWidget {
  final String name;
  final AppCaptionStyle style;
  final Color accentColor;

  /// True when drawn along the bottom edge of the card, where a bar runs edge to edge.
  final bool onCard;

  const AppCaption({
    super.key,
    required this.name,
    required this.style,
    required this.accentColor,
    this.onCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final centered = style.alignment == AppCaptionAlignment.center;
    final text = Text(
      style.apply(name),
      style: style.textStyle(context, accentColor),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: centered ? TextAlign.center : TextAlign.start,
    );

    final decoration = style.decoration(accentColor, flushBottom: onCard);
    if (decoration == null) {
      return _fillWidth(text);
    }

    final box = DecoratedBox(
      decoration: decoration,
      child: Padding(padding: style.boxPadding, child: text),
    );

    if (style.background == AppCaptionBackground.bar) {
      return _fillWidth(box);
    }
    // Pills and bare shadows hug the text.
    return Align(
      alignment: centered ? Alignment.center : AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: box,
    );
  }

  /// Stretches [child] across the available width, so text alignment applies, when that width is bounded.
  static Widget _fillWidth(Widget child) => LayoutBuilder(
        builder: (context, constraints) =>
            constraints.hasBoundedWidth ? SizedBox(width: constraints.maxWidth, child: child) : child,
      );
}
