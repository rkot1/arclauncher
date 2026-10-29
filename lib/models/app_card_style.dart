import 'dart:typed_data';

import 'package:flauncher/app_image_type.dart';
import 'package:flauncher/custom_fonts.dart';
import 'package:flutter/material.dart';

enum AppCaptionVisibility { hidden, always, focused }

enum AppCaptionPosition { below, overlay }

enum AppCaptionCase { normal, uppercase }

enum AppCaptionAlignment { start, center }

enum AppCaptionColor { theme, white, muted, accent }

enum AppCaptionBackground { none, pill, bar }

enum AppCaptionTextShadow { none, soft, strong, outline }

enum AppCaptionBoxShadow { none, soft, strong, glow }

/// Android system font families, resolved through /system/etc/fonts.xml.
/// Devices missing one of them silently fall back to the default font.
const List<String> kSystemCaptionFonts = [
  '',
  'sans-serif-condensed',
  'sans-serif-light',
  'sans-serif-medium',
  'sans-serif-black',
  'serif',
  'monospace',
  'serif-monospace',
  'casual',
  'cursive',
  'sans-serif-smallcaps',
];

const List<double> kCaptionFontSizes = [10, 11, 12, 13, 14, 15, 16, 18, 20, 22];

const List<int> kCaptionFontWeights = [300, 400, 500, 600, 700, 900];

/// Space between the card and a caption drawn below it.
const double kCaptionGap = 8.0;
const double _captionLineHeight = 1.25;
const double _captionBoxVerticalPadding = 3.0;
const double _captionBoxHorizontalPadding = 8.0;

@immutable
class AppCaptionStyle {
  final AppCaptionVisibility visibility;
  final AppCaptionPosition position;

  /// Empty for the default font, an Android family name, or a [CustomFonts] file key.
  final String font;
  final double fontSize;
  final int fontWeight;
  final AppCaptionCase letterCase;
  final AppCaptionAlignment alignment;
  final AppCaptionColor color;
  final AppCaptionBackground background;
  final AppCaptionTextShadow textShadow;
  final AppCaptionBoxShadow boxShadow;

  const AppCaptionStyle({
    this.visibility = AppCaptionVisibility.hidden,
    this.position = AppCaptionPosition.below,
    this.font = '',
    this.fontSize = 12,
    this.fontWeight = 400,
    this.letterCase = AppCaptionCase.normal,
    this.alignment = AppCaptionAlignment.center,
    this.color = AppCaptionColor.theme,
    this.background = AppCaptionBackground.none,
    this.textShadow = AppCaptionTextShadow.none,
    this.boxShadow = AppCaptionBoxShadow.none,
  });

  bool get visible => visibility != AppCaptionVisibility.hidden;

  bool get hasBox => background != AppCaptionBackground.none || boxShadow != AppCaptionBoxShadow.none;

  /// Vertical space the caption needs below the card; zero when it is drawn on the card or hidden.
  double get reservedHeight {
    if (!visible || position != AppCaptionPosition.below) {
      return 0;
    }
    // Leave room for the blur of a box shadow so the row does not clip it.
    final shadowAllowance = boxShadow == AppCaptionBoxShadow.none ? 0.0 : 4.0;
    return (kCaptionGap + boxHeight + shadowAllowance).ceilToDouble() + 1;
  }

  /// Height of the caption itself, including its background padding.
  double get boxHeight => fontSize * _captionLineHeight + (hasBox ? 2 * _captionBoxVerticalPadding : 0);

  String apply(String name) => letterCase == AppCaptionCase.uppercase ? name.toUpperCase() : name;

  TextStyle textStyle(BuildContext context, Color accentColor) {
    final Color? textColor = switch (color) {
      AppCaptionColor.theme => Theme.of(context).textTheme.bodySmall?.color,
      AppCaptionColor.white => Colors.white,
      AppCaptionColor.muted => Colors.white60,
      AppCaptionColor.accent => accentColor,
    };

    return TextStyle(
      fontFamily: CustomFonts.familyFor(font),
      fontSize: fontSize,
      height: _captionLineHeight,
      fontWeight: FontWeight.values[(fontWeight ~/ 100).clamp(1, 9) - 1],
      letterSpacing: letterCase == AppCaptionCase.uppercase ? fontSize * 0.08 : null,
      color: textColor,
      shadows: _textShadows(),
    );
  }

  List<Shadow>? _textShadows() {
    switch (textShadow) {
      case AppCaptionTextShadow.none:
        return null;
      case AppCaptionTextShadow.soft:
        return const [Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 1))];
      case AppCaptionTextShadow.strong:
        return const [
          Shadow(color: Color(0xDD000000), blurRadius: 8, offset: Offset(0, 2)),
          Shadow(color: Color(0xFF000000), blurRadius: 2, offset: Offset(0, 1)),
        ];
      case AppCaptionTextShadow.outline:
        final d = fontSize >= 16 ? 1.5 : 1.0;
        return [
          for (final offset in [
            Offset(-d, -d), Offset(0, -d), Offset(d, -d),
            Offset(-d, 0), Offset(d, 0),
            Offset(-d, d), Offset(0, d), Offset(d, d),
          ])
            Shadow(color: const Color(0xE6000000), blurRadius: 0.5, offset: offset),
        ];
    }
  }

  /// Decoration of the caption box, or null when the caption is bare text.
  BoxDecoration? decoration(Color accentColor, {bool flushBottom = false}) {
    if (!hasBox) {
      return null;
    }

    final Color? fill = switch (background) {
      AppCaptionBackground.none => null,
      AppCaptionBackground.pill => const Color(0xB3000000),
      AppCaptionBackground.bar => const Color(0x99000000),
    };
    final BorderRadius radius = switch (background) {
      AppCaptionBackground.bar when flushBottom => BorderRadius.zero,
      AppCaptionBackground.bar => BorderRadius.circular(6),
      _ => BorderRadius.circular(fontSize),
    };
    final List<BoxShadow>? shadows = switch (boxShadow) {
      AppCaptionBoxShadow.none => null,
      AppCaptionBoxShadow.soft => const [BoxShadow(color: Color(0x73000000), blurRadius: 8, offset: Offset(0, 2))],
      AppCaptionBoxShadow.strong => const [
          BoxShadow(color: Color(0xCC000000), blurRadius: 14, spreadRadius: 1, offset: Offset(0, 4)),
        ],
      AppCaptionBoxShadow.glow => [
          BoxShadow(color: accentColor.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 1),
        ],
    };

    return BoxDecoration(color: fill, borderRadius: radius, boxShadow: shadows);
  }

  EdgeInsets get boxPadding => hasBox
      ? const EdgeInsets.symmetric(horizontal: _captionBoxHorizontalPadding, vertical: _captionBoxVerticalPadding)
      : EdgeInsets.zero;

  AppCaptionStyle copyWith({
    AppCaptionVisibility? visibility,
    AppCaptionPosition? position,
    String? font,
    double? fontSize,
    int? fontWeight,
    AppCaptionCase? letterCase,
    AppCaptionAlignment? alignment,
    AppCaptionColor? color,
    AppCaptionBackground? background,
    AppCaptionTextShadow? textShadow,
    AppCaptionBoxShadow? boxShadow,
  }) =>
      AppCaptionStyle(
        visibility: visibility ?? this.visibility,
        position: position ?? this.position,
        font: font ?? this.font,
        fontSize: fontSize ?? this.fontSize,
        fontWeight: fontWeight ?? this.fontWeight,
        letterCase: letterCase ?? this.letterCase,
        alignment: alignment ?? this.alignment,
        color: color ?? this.color,
        background: background ?? this.background,
        textShadow: textShadow ?? this.textShadow,
        boxShadow: boxShadow ?? this.boxShadow,
      );

  @override
  bool operator ==(Object other) =>
      other is AppCaptionStyle &&
      other.visibility == visibility &&
      other.position == position &&
      other.font == font &&
      other.fontSize == fontSize &&
      other.fontWeight == fontWeight &&
      other.letterCase == letterCase &&
      other.alignment == alignment &&
      other.color == color &&
      other.background == background &&
      other.textShadow == textShadow &&
      other.boxShadow == boxShadow;

  @override
  int get hashCode => Object.hash(visibility, position, font, fontSize, fontWeight, letterCase, alignment, color,
      background, textShadow, boxShadow);
}

/// What an app card shows.
enum AppCardImageMode {
  /// The app banner, or its icon next to its name when it has none.
  banner,

  /// The app banner, or its icon on the generic background when it has none.
  bannerOrIcon,

  /// The icon on the generic background for every app (custom banners still win).
  icon,
}

/// Which part of the launcher icon is pulled from the app package.
enum AppIconVariant { full, foreground, monochrome }

enum AppIconSize {
  small(0.46),
  medium(0.6),
  large(0.74);

  /// Icon height as a fraction of the card height.
  final double factor;

  const AppIconSize(this.factor);
}

enum AppIconTint { white, accent, iconColor }

enum AppCardBackground { iconColor, color, gradient, glass, image }

enum AppCardShadow { none, normal, strong, glow }

const List<String> kAppCardBackgroundColors = [
  '2C2C31', // graphite
  '000000', // black
  '37474F', // slate
  '1A237E', // midnight
  '0D47A1', // ocean
  '004D40', // pine
  '1B5E20', // forest
  '4A148C', // plum
  '880E4F', // wine
  'BF360C', // rust
  '5D4037', // cocoa
  'ECEFF1', // cloud
];

const List<List<Color>> kAppCardGradients = [
  [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
  [Color(0xFF0F2027), Color(0xFF2C5364)],
  [Color(0xFF42275A), Color(0xFF734B6D)],
  [Color(0xFF3A1C71), Color(0xFFD76D77)],
  [Color(0xFF134E5E), Color(0xFF71B280)],
  [Color(0xFF232526), Color(0xFF414345)],
  [Color(0xFF000000), Color(0xFF434343)],
  [Color(0xFF1D2B64), Color(0xFFF8CDDA)],
];

@immutable
class AppIconStyle {
  final AppCardImageMode mode;
  final AppIconVariant variant;
  final AppIconSize size;
  final AppIconTint tint;
  final AppCardBackground background;
  final String backgroundColorHex;
  final int gradientIndex;
  final String backgroundImagePath;
  final AppCardShadow shadow;

  const AppIconStyle({
    this.mode = AppCardImageMode.banner,
    this.variant = AppIconVariant.full,
    this.size = AppIconSize.medium,
    this.tint = AppIconTint.white,
    this.background = AppCardBackground.iconColor,
    this.backgroundColorHex = '2C2C31',
    this.gradientIndex = 0,
    this.backgroundImagePath = '',
    this.shadow = AppCardShadow.normal,
  });

  Color get backgroundColor => Color(int.parse('FF$backgroundColorHex', radix: 16));

  List<Color> get gradientColors => kAppCardGradients[gradientIndex.clamp(0, kAppCardGradients.length - 1)];

  /// Whether the app card material is see-through and the face paints its own background.
  bool get translucentCard => mode != AppCardImageMode.banner && background == AppCardBackground.glass;

  AppIconStyle copyWith({
    AppCardImageMode? mode,
    AppIconVariant? variant,
    AppIconSize? size,
    AppIconTint? tint,
    AppCardBackground? background,
    String? backgroundColorHex,
    int? gradientIndex,
    String? backgroundImagePath,
    AppCardShadow? shadow,
  }) =>
      AppIconStyle(
        mode: mode ?? this.mode,
        variant: variant ?? this.variant,
        size: size ?? this.size,
        tint: tint ?? this.tint,
        background: background ?? this.background,
        backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
        gradientIndex: gradientIndex ?? this.gradientIndex,
        backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
        shadow: shadow ?? this.shadow,
      );

  @override
  bool operator ==(Object other) =>
      other is AppIconStyle &&
      other.mode == mode &&
      other.variant == variant &&
      other.size == size &&
      other.tint == tint &&
      other.background == background &&
      other.backgroundColorHex == backgroundColorHex &&
      other.gradientIndex == gradientIndex &&
      other.backgroundImagePath == backgroundImagePath &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(
      mode, variant, size, tint, background, backgroundColorHex, gradientIndex, backgroundImagePath, shadow);
}

/// An icon rendered by the platform for a given [AppIconVariant].
class AppIconImage {
  final Uint8List bytes;

  /// The variant actually rendered: apps without an adaptive or themed icon fall back to [AppIconVariant.full].
  final AppIconVariant variant;

  /// Average colour of the full icon, used for icon-coloured backgrounds.
  final Color? dominantColor;

  const AppIconImage({required this.bytes, required this.variant, this.dominantColor});
}

/// What an app card draws, as resolved from its [AppIconStyle].
class AppCardImage {
  final AppImageType type;
  final Uint8List bytes;

  /// Set when the icon is drawn on the generic background rather than next to the app name.
  final AppIconImage? icon;

  const AppCardImage({required this.type, required this.bytes, this.icon});
}
