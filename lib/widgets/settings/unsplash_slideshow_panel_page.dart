/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/slideshow_sources_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnsplashSlideshowPanelPage extends StatelessWidget {
  static const String routeName = "unsplash_slideshow_panel";

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        final hasKey = settings.unsplashAccessKey.isNotEmpty;
        Future<void> editKey() async {
          final key = await _askText(context, localizations.unsplashAccessKey, settings.unsplashAccessKey,
              help: localizations.unsplashAccessKeyHelp);
          if (key != null) await settings.setUnsplashAccessKey(key);
        }

        return Column(
          children: [
            SettingsPageHeader(title: localizations.unsplashSlideshow),
            RoundedSwitchListTile(
              autofocus: true,
              title: Text(localizations.unsplashEnable),
              secondary: const Icon(Icons.slideshow),
              value: settings.unsplashSlideshowEnabled,
              // Without a key the switch asks for one instead of enabling a slideshow that cannot run.
              onChanged: (value) => hasKey ? settings.setUnsplashSlideshowEnabled(value) : editKey(),
            ),
            if (settings.unsplashSlideshowEnabled)
              FocusableSettingsTile(
                leading: const Icon(Icons.skip_next),
                title: Text(localizations.unsplashNextPhoto),
                onPressed: () => _showNextPhoto(context, localizations),
              ),
            FocusableSettingsTile(
              leading: const Icon(Icons.key),
              title: Text(localizations.unsplashAccessKey),
              trailing: Text(hasKey ? "••••${_tail(settings.unsplashAccessKey)}" : localizations.unsplashNotSet),
              onPressed: editKey,
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(localizations.unsplashInterval),
              trailing: Text(localizations.unsplashIntervalMinutes(settings.unsplashIntervalMinutes)),
              onPressed: () => settings.setUnsplashIntervalMinutes(_nextInterval(settings.unsplashIntervalMinutes)),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(localizations.slideshowCategories),
              onPressed: () => Navigator.of(context).pushNamed(SlideshowSourcesPanelPage.routeName),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNextPhoto(BuildContext context, AppLocalizations localizations) async {
    final wallpaperService = context.read<WallpaperService>();
    // Snack bars are light on the dark theme, so the spinner takes their text colour.
    final spinnerColor = Theme.of(context).colorScheme.onInverseSurface;
    final messenger = ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: spinnerColor),
              ),
              const SizedBox(width: 12),
              Text(localizations.unsplashNextPhotoLoading),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );
    bool shown;
    try {
      shown = await wallpaperService.nextSlideshowPhoto();
    } on StateError {
      shown = false;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(shown ? localizations.unsplashNextPhotoShown : localizations.unsplashNextPhotoFailed),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  static String _tail(String key) => key.length <= 4 ? "" : key.substring(key.length - 4);

  /// Cycles through [SettingsService.unsplashIntervalChoices] on each OK press.
  static int _nextInterval(int current) {
    const choices = SettingsService.unsplashIntervalChoices;
    final index = choices.indexOf(current);
    return choices[(index + 1) % choices.length];
  }

  Future<String?> _askText(BuildContext context, String title, String initialValue, {String? help}) =>
      showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          insetPadding: const EdgeInsets.only(bottom: 120),
          contentPadding: const EdgeInsets.all(24),
          title: Text(title),
          children: [
            if (help != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(help)),
            TextFormField(
              autofocus: true,
              initialValue: initialValue,
              keyboardType: TextInputType.text,
              onFieldSubmitted: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
      );
}
