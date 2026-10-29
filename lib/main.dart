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

import 'dart:async';

import 'package:flauncher/custom_fonts.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/launcher_commands.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'flauncher_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();

  final sharedPreferences = await SharedPreferences.getInstance();
  final settingsService = SettingsService(sharedPreferences);
  // Captions re-layout once a custom font finishes loading, so this need not block startup.
  unawaited(CustomFonts.ensureLoaded(settingsService.appCaptionStyle.font));
  final fLauncherChannel = FLauncherChannel();
  final fLauncherDatabase = FLauncherDatabase(connect());

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => settingsService,
            lazy: false),
        ChangeNotifierProvider(create: (_) => AppsService(fLauncherChannel, fLauncherDatabase)),
        ChangeNotifierProvider(create: (_) => LauncherState()),
        ChangeNotifierProvider(create: (_) => NetworkService(fLauncherChannel)),
        ChangeNotifierProvider(
            create: (context) {
              SettingsService settingsService = Provider.of(context, listen: false);
              return WallpaperService(settingsService);
            }
        ),
        ChangeNotifierProvider(
            create: (_) => BrightnessService(sharedPreferences),
            lazy: false
        ),
        ChangeNotifierProvider(
            create: (context) {
              final settingsService = Provider.of<SettingsService>(context, listen: false);
              return WatchNextService(fLauncherChannel, settingsService: settingsService);
            },
            lazy: false
        ),
        Provider(
            create: (context) => BackupService(
                  sharedPreferences,
                  Provider.of(context, listen: false),
                  Provider.of(context, listen: false),
                  Provider.of(context, listen: false),
                ),
            lazy: false
        ),
        Provider(
            create: (context) => LauncherCommands(
                  Provider.of(context, listen: false),
                  Provider.of(context, listen: false),
                )..attach(),
            dispose: (_, LauncherCommands commands) => commands.detach(),
            lazy: false
        ),
      ],
      child: FLauncherApp()
    )
  );
}
