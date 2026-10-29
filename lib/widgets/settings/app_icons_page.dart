import 'dart:io';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/app_card_style.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/app_card_style_preview.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_choice_tile.dart';
import 'package:flauncher/widgets/settings/settings_theme.dart';
import 'package:flauncher/widgets/tv_media_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class AppIconsPage extends StatelessWidget {
  static const String routeName = "app_icons_panel";

  const AppIconsPage({super.key});

  Future<void> _pickBackgroundImage(BuildContext context, SettingsService service) async {
    final media = await TvMediaPicker.show(context, mode: TvMediaPickerMode.image);
    if (media == null) {
      return;
    }

    final docDir = await getApplicationDocumentsDirectory();
    // A new name per pick, so cards do not keep the previous image from the image cache.
    final target = File(p.join(docDir.path, 'app_card_background_${DateTime.now().millisecondsSinceEpoch}'));
    await File(media.path).copy(target.path);

    final previous = service.appIconStyle.backgroundImagePath;
    await service.setAppIconStyle(
      service.appIconStyle.copyWith(background: AppCardBackground.image, backgroundImagePath: target.path),
    );
    if (previous.isNotEmpty) {
      try {
        await File(previous).delete();
      } catch (_) {
        // Already gone.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<SettingsService>(
      builder: (context, service, _) {
        final style = service.appIconStyle;
        void update(AppIconStyle style) => service.setAppIconStyle(style);
        final showsIcons = style.mode != AppCardImageMode.banner;

        return Column(
          children: [
            SettingsPageHeader(title: localizations.appIconsSettings),
            const AppCardStylePreview(),
            const SettingsSectionDivider(),
            Expanded(
              child: ListView(
                children: [
                  SettingsChoiceTile<AppCardImageMode>(
                    key: const ValueKey('mode'),
                    autofocus: true,
                    icon: Icons.view_carousel_outlined,
                    title: localizations.appCardImageMode,
                    values: AppCardImageMode.values,
                    value: style.mode,
                    labelOf: (value) => switch (value) {
                      AppCardImageMode.banner => localizations.cardModeBanner,
                      AppCardImageMode.bannerOrIcon => localizations.cardModeBannerOrIcon,
                      AppCardImageMode.icon => localizations.cardModeIcon,
                    },
                    onChanged: (value) => update(style.copyWith(mode: value)),
                  ),
                  if (showsIcons) ...[
                    SettingsChoiceTile<AppIconVariant>(
                      key: const ValueKey('variant'),
                      icon: Icons.layers_outlined,
                      title: localizations.appIconVariant,
                      values: AppIconVariant.values,
                      value: style.variant,
                      labelOf: (value) => switch (value) {
                        AppIconVariant.full => localizations.iconVariantFull,
                        AppIconVariant.foreground => localizations.iconVariantForeground,
                        AppIconVariant.monochrome => localizations.iconVariantMonochrome,
                      },
                      onChanged: (value) => update(style.copyWith(variant: value)),
                    ),
                    SettingsChoiceTile<AppIconSize>(
                      key: const ValueKey('size'),
                      icon: Icons.photo_size_select_large,
                      title: localizations.appIconSize,
                      values: AppIconSize.values,
                      value: style.size,
                      labelOf: (value) => switch (value) {
                        AppIconSize.small => localizations.sizeSmall,
                        AppIconSize.medium => localizations.sizeMedium,
                        AppIconSize.large => localizations.sizeLarge,
                      },
                      onChanged: (value) => update(style.copyWith(size: value)),
                    ),
                    if (style.variant == AppIconVariant.monochrome)
                      SettingsChoiceTile<AppIconTint>(
                        key: const ValueKey('tint'),
                        icon: Icons.colorize_outlined,
                        title: localizations.appIconTint,
                        values: AppIconTint.values,
                        value: style.tint,
                        labelOf: (value) => switch (value) {
                          AppIconTint.white => localizations.colorWhite,
                          AppIconTint.accent => localizations.captionColorAccent,
                          AppIconTint.iconColor => localizations.iconColor,
                        },
                        onChanged: (value) => update(style.copyWith(tint: value)),
                      ),
                    SettingsChoiceTile<AppCardBackground>(
                      key: const ValueKey('background'),
                      icon: Icons.format_paint_outlined,
                      title: localizations.appCardBackground,
                      values: AppCardBackground.values,
                      value: style.background,
                      labelOf: (value) => switch (value) {
                        AppCardBackground.iconColor => localizations.iconColor,
                        AppCardBackground.wallpaper => localizations.backgroundWallpaperColors,
                        AppCardBackground.color => localizations.backgroundSolidColor,
                        AppCardBackground.gradient => localizations.backgroundGradient,
                        AppCardBackground.glass => localizations.backgroundTranslucent,
                        AppCardBackground.image => localizations.backgroundImage,
                      },
                      onChanged: (value) => update(style.copyWith(background: value)),
                    ),
                    if (style.background == AppCardBackground.color ||
                        (style.background == AppCardBackground.image && style.backgroundImagePath.isEmpty))
                      SettingsChoiceTile<String>(
                        key: const ValueKey('color'),
                        icon: Icons.palette_outlined,
                        title: localizations.backgroundSolidColor,
                        values: kAppCardBackgroundColors,
                        value: style.backgroundColorHex,
                        labelOf: (hex) => '#$hex',
                        swatchOf: (hex) => SettingsColorSwatch(color: Color(int.parse('FF$hex', radix: 16))),
                        onChanged: (hex) => update(style.copyWith(backgroundColorHex: hex)),
                      ),
                    if (style.background == AppCardBackground.gradient)
                      SettingsChoiceTile<int>(
                        key: const ValueKey('gradient'),
                        icon: Icons.gradient,
                        title: localizations.backgroundGradient,
                        values: List.generate(kAppCardGradients.length, (index) => index),
                        value: style.gradientIndex,
                        labelOf: (index) => '${index + 1} / ${kAppCardGradients.length}',
                        swatchOf: (index) => SettingsColorSwatch(
                          gradient: LinearGradient(colors: kAppCardGradients[index]),
                        ),
                        onChanged: (index) => update(style.copyWith(gradientIndex: index)),
                      ),
                    if (style.background == AppCardBackground.image)
                      FocusableSettingsTile(
                        key: const ValueKey('image'),
                        leading: const Icon(Icons.image_search),
                        title: Text(localizations.backgroundChooseImage, style: Theme.of(context).textTheme.bodyMedium),
                        subtitle: Text(
                          style.backgroundImagePath.isEmpty
                              ? localizations.backgroundNoImage
                              : p.basename(style.backgroundImagePath),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onPressed: () => _pickBackgroundImage(context, service),
                      ),
                  ],
                  SettingsChoiceTile<AppCardShadow>(
                    key: const ValueKey('shadow'),
                    icon: Icons.shield_moon_outlined,
                    title: localizations.appCardShadow,
                    values: AppCardShadow.values,
                    value: style.shadow,
                    labelOf: (value) => switch (value) {
                      AppCardShadow.none => localizations.styleNone,
                      AppCardShadow.normal => localizations.shadowDefault,
                      AppCardShadow.strong => localizations.shadowStrong,
                      AppCardShadow.glow => localizations.shadowGlow,
                    },
                    onChanged: (value) => update(style.copyWith(shadow: value)),
                  ),
                  if (showsIcons)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                      child: Text(
                        localizations.appIconsHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
