import 'dart:io';

import 'package:flauncher/models/app_card_style.dart';
import 'package:flutter/material.dart';

/// An app icon centred on the generic card background chosen in [AppIconStyle].
class AppIconFace extends StatelessWidget {
  final ImageProvider image;
  final AppIconImage icon;
  final AppIconStyle style;
  final Color accentColor;

  /// Space kept free at the bottom, for a caption drawn on the card.
  final double bottomInset;

  const AppIconFace({
    super.key,
    required this.image,
    required this.icon,
    required this.style,
    required this.accentColor,
    this.bottomInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final Color? tint = icon.variant == AppIconVariant.monochrome ? _tintColor() : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        AppCardBackgroundView(style: style, iconColor: icon.dominantColor),
        Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Center(
            child: FractionallySizedBox(
              heightFactor: style.size.factor,
              child: AspectRatio(
                aspectRatio: 1,
                child: Image(
                  image: image,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  color: tint,
                  colorBlendMode: tint != null ? BlendMode.srcIn : null,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _tintColor() => switch (style.tint) {
        AppIconTint.white => Colors.white,
        AppIconTint.accent => accentColor,
        AppIconTint.iconColor => _lighten(icon.dominantColor ?? Colors.white),
      };

  static Color _lighten(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(hsl.lightness.clamp(0.62, 0.85)).toColor();
  }
}

/// The generic background behind icons on app cards.
class AppCardBackgroundView extends StatelessWidget {
  final AppIconStyle style;

  /// Dominant colour of the app icon, for [AppCardBackground.iconColor].
  final Color? iconColor;

  const AppCardBackgroundView({super.key, required this.style, this.iconColor});

  @override
  Widget build(BuildContext context) {
    switch (style.background) {
      case AppCardBackground.iconColor:
        final base = HSLColor.fromColor(iconColor ?? const Color(0xFF2C2C31));
        // Keep the tone dark enough for icons and captions to stand out.
        final saturation = base.saturation.clamp(0.0, 0.65);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withSaturation(saturation).withLightness(0.34).toColor(),
                base.withSaturation(saturation).withLightness(0.17).toColor(),
              ],
            ),
          ),
        );
      case AppCardBackground.color:
        return ColoredBox(color: style.backgroundColor);
      case AppCardBackground.gradient:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.gradientColors,
            ),
          ),
        );
      case AppCardBackground.glass:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.06)],
            ),
          ),
        );
      case AppCardBackground.image:
        if (style.backgroundImagePath.isEmpty) {
          return ColoredBox(color: style.backgroundColor);
        }
        return Image(
          image: ResizeImage(FileImage(File(style.backgroundImagePath)), width: 480),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => ColoredBox(color: style.backgroundColor),
        );
    }
  }
}
