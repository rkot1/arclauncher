import 'package:flauncher/custom_fonts.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/app_card_style.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/app_card_style_preview.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_choice_tile.dart';
import 'package:flauncher/widgets/settings/settings_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const Map<String, String> _systemFontNames = {
  'sans-serif-condensed': 'Condensed',
  'sans-serif-light': 'Light',
  'sans-serif-medium': 'Medium',
  'sans-serif-black': 'Black',
  'serif': 'Serif',
  'monospace': 'Monospace',
  'serif-monospace': 'Serif Mono',
  'casual': 'Casual',
  'cursive': 'Cursive',
  'sans-serif-smallcaps': 'Small Caps',
};

class AppCaptionsPage extends StatefulWidget {
  static const String routeName = "app_captions_panel";

  const AppCaptionsPage({super.key});

  @override
  State<AppCaptionsPage> createState() => _AppCaptionsPageState();
}

class _AppCaptionsPageState extends State<AppCaptionsPage> {
  List<String> _customFonts = const [];
  String? _fontsDirectory;

  @override
  void initState() {
    super.initState();
    _loadCustomFonts();
  }

  Future<void> _loadCustomFonts() async {
    final fonts = await CustomFonts.list();
    final directory = await CustomFonts.directory();
    if (mounted) {
      setState(() {
        _customFonts = fonts;
        _fontsDirectory = directory.path;
      });
    }
  }

  Future<void> _setFont(SettingsService service, String font) async {
    await CustomFonts.ensureLoaded(font);
    await service.setAppCaptionStyle(service.appCaptionStyle.copyWith(font: font));
  }

  Future<void> _importFont(SettingsService service) async {
    final font = await CustomFonts.import(FLauncherChannel());
    await _loadCustomFonts();
    if (font != null) {
      await _setFont(service, font);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<SettingsService>(
      builder: (context, service, _) {
        final style = service.appCaptionStyle;
        void update(AppCaptionStyle style) => service.setAppCaptionStyle(style);

        final fonts = [
          ...kSystemCaptionFonts,
          ..._customFonts,
          if (style.font.isNotEmpty && !kSystemCaptionFonts.contains(style.font) && !_customFonts.contains(style.font))
            style.font,
        ];

        return Column(
          children: [
            SettingsPageHeader(title: localizations.appCaptionsSettings),
            const AppCardStylePreview(),
            const SettingsSectionDivider(),
            Expanded(
              child: ListView(
                children: [
                  SettingsChoiceTile<AppCaptionVisibility>(
                    key: const ValueKey('visibility'),
                    autofocus: true,
                    icon: Icons.subtitles_outlined,
                    title: localizations.captionVisibility,
                    values: AppCaptionVisibility.values,
                    value: style.visibility,
                    labelOf: (value) => switch (value) {
                      AppCaptionVisibility.hidden => localizations.captionVisibilityHidden,
                      AppCaptionVisibility.always => localizations.captionVisibilityAlways,
                      AppCaptionVisibility.focused => localizations.captionVisibilityFocused,
                    },
                    onChanged: (value) => update(style.copyWith(visibility: value)),
                  ),
                  if (style.visible) ...[
                    SettingsChoiceTile<AppCaptionPosition>(
                      key: const ValueKey('position'),
                      icon: Icons.vertical_align_bottom,
                      title: localizations.captionPosition,
                      values: AppCaptionPosition.values,
                      value: style.position,
                      labelOf: (value) => switch (value) {
                        AppCaptionPosition.below => localizations.captionPositionBelow,
                        AppCaptionPosition.overlay => localizations.captionPositionOverlay,
                      },
                      onChanged: (value) => update(style.copyWith(position: value)),
                    ),
                    SettingsChoiceTile<String>(
                      key: const ValueKey('font'),
                      icon: Icons.font_download_outlined,
                      title: localizations.captionFont,
                      values: fonts,
                      value: style.font,
                      labelOf: (font) => _fontName(localizations, font),
                      swatchOf: (font) => Text(
                        'Aa',
                        style: TextStyle(
                          fontFamily: CustomFonts.familyFor(font),
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      onChanged: (font) => _setFont(service, font),
                    ),
                    FocusableSettingsTile(
                      key: const ValueKey('import_font'),
                      leading: const Icon(Icons.upload_file_outlined),
                      title: Text(localizations.captionImportFont, style: Theme.of(context).textTheme.bodyMedium),
                      subtitle: _fontsDirectory != null
                          ? Text(
                              localizations.captionImportFontHint(_fontsDirectory!),
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : null,
                      onPressed: () => _importFont(service),
                    ),
                    SettingsChoiceTile<double>(
                      key: const ValueKey('size'),
                      icon: Icons.format_size,
                      title: localizations.captionFontSize,
                      values: kCaptionFontSizes,
                      value: style.fontSize,
                      labelOf: (size) => size.toStringAsFixed(0),
                      onChanged: (size) => update(style.copyWith(fontSize: size)),
                    ),
                    SettingsChoiceTile<int>(
                      key: const ValueKey('weight'),
                      icon: Icons.format_bold,
                      title: localizations.captionFontWeight,
                      values: kCaptionFontWeights,
                      value: style.fontWeight,
                      labelOf: (weight) => switch (weight) {
                        300 => localizations.fontWeightLight,
                        400 => localizations.fontWeightRegular,
                        500 => localizations.fontWeightMedium,
                        600 => localizations.fontWeightSemiBold,
                        700 => localizations.fontWeightBold,
                        _ => localizations.fontWeightBlack,
                      },
                      onChanged: (weight) => update(style.copyWith(fontWeight: weight)),
                    ),
                    SettingsChoiceTile<AppCaptionCase>(
                      key: const ValueKey('case'),
                      icon: Icons.text_fields,
                      title: localizations.captionLetterCase,
                      values: AppCaptionCase.values,
                      value: style.letterCase,
                      labelOf: (value) => switch (value) {
                        AppCaptionCase.normal => localizations.captionCaseNormal,
                        AppCaptionCase.uppercase => localizations.captionCaseUppercase,
                      },
                      onChanged: (value) => update(style.copyWith(letterCase: value)),
                    ),
                    SettingsChoiceTile<AppCaptionAlignment>(
                      key: const ValueKey('alignment'),
                      icon: Icons.format_align_center,
                      title: localizations.captionAlignment,
                      values: AppCaptionAlignment.values,
                      value: style.alignment,
                      labelOf: (value) => switch (value) {
                        AppCaptionAlignment.start => localizations.captionAlignStart,
                        AppCaptionAlignment.center => localizations.captionAlignCenter,
                      },
                      onChanged: (value) => update(style.copyWith(alignment: value)),
                    ),
                    SettingsChoiceTile<AppCaptionColor>(
                      key: const ValueKey('color'),
                      icon: Icons.format_color_text,
                      title: localizations.captionColor,
                      values: AppCaptionColor.values,
                      value: style.color,
                      labelOf: (value) => switch (value) {
                        AppCaptionColor.theme => localizations.captionColorTheme,
                        AppCaptionColor.white => localizations.colorWhite,
                        AppCaptionColor.muted => localizations.captionColorMuted,
                        AppCaptionColor.accent => localizations.captionColorAccent,
                      },
                      swatchOf: (value) => SettingsColorSwatch(
                        color: switch (value) {
                          AppCaptionColor.theme => Theme.of(context).textTheme.bodySmall?.color,
                          AppCaptionColor.white => Colors.white,
                          AppCaptionColor.muted => Colors.white60,
                          AppCaptionColor.accent => service.accentColor,
                        },
                      ),
                      onChanged: (value) => update(style.copyWith(color: value)),
                    ),
                    SettingsChoiceTile<AppCaptionBackground>(
                      key: const ValueKey('background'),
                      icon: Icons.rectangle_outlined,
                      title: localizations.captionBackground,
                      values: AppCaptionBackground.values,
                      value: style.background,
                      labelOf: (value) => switch (value) {
                        AppCaptionBackground.none => localizations.styleNone,
                        AppCaptionBackground.pill => localizations.captionBackgroundPill,
                        AppCaptionBackground.bar => localizations.captionBackgroundBar,
                      },
                      onChanged: (value) => update(style.copyWith(background: value)),
                    ),
                    SettingsChoiceTile<AppCaptionTextShadow>(
                      key: const ValueKey('text_shadow'),
                      icon: Icons.format_color_fill,
                      title: localizations.captionTextShadow,
                      values: AppCaptionTextShadow.values,
                      value: style.textShadow,
                      labelOf: (value) => switch (value) {
                        AppCaptionTextShadow.none => localizations.styleNone,
                        AppCaptionTextShadow.soft => localizations.shadowSoft,
                        AppCaptionTextShadow.strong => localizations.shadowStrong,
                        AppCaptionTextShadow.outline => localizations.shadowOutline,
                      },
                      onChanged: (value) => update(style.copyWith(textShadow: value)),
                    ),
                    SettingsChoiceTile<AppCaptionBoxShadow>(
                      key: const ValueKey('box_shadow'),
                      icon: Icons.layers_outlined,
                      title: localizations.captionBoxShadow,
                      values: AppCaptionBoxShadow.values,
                      value: style.boxShadow,
                      labelOf: (value) => switch (value) {
                        AppCaptionBoxShadow.none => localizations.styleNone,
                        AppCaptionBoxShadow.soft => localizations.shadowSoft,
                        AppCaptionBoxShadow.strong => localizations.shadowStrong,
                        AppCaptionBoxShadow.glow => localizations.shadowGlow,
                      },
                      onChanged: (value) => update(style.copyWith(boxShadow: value)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _fontName(AppLocalizations localizations, String font) {
    if (font.isEmpty) {
      return localizations.captionFontDefault;
    }
    if (CustomFonts.isCustom(font)) {
      return CustomFonts.displayName(font);
    }
    return _systemFontNames[font] ?? font;
  }
}
