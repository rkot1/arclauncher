import 'dart:convert';
import 'dart:io';

import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../mocks.mocks.dart';

const _layout = {
  "sections": [
    {"kind": "spacer", "height": 40},
  ],
  "hiddenApps": [],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late SettingsService settingsService;
  late MockAppsService appsService;
  late Directory directory;
  late BackupService backupService;

  setUp(() async {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    SharedPreferences.resetStatic();
    preferences = await SharedPreferences.getInstance();
    settingsService = SettingsService(preferences);
    appsService = MockAppsService();
    when(appsService.initialized).thenReturn(true);
    when(appsService.exportLayout()).thenAnswer((_) async => _layout);
    when(appsService.restoreLayout(any)).thenAnswer((_) async => (skippedApps: 2, addedApps: 1));
    directory = Directory.systemTemp.createTempSync("arc_backup_test");
    addTearDown(() => directory.deleteSync(recursive: true));
    backupService = BackupService(
      preferences,
      settingsService,
      BrightnessService(preferences),
      appsService,
      directory: () async => directory,
    );
  });

  group("settings", () {
    test("exports changed settings, without secrets or device state", () async {
      await preferences.setDouble("app_caption_font_size", 16);
      await preferences.setString("accent_color", "00BFA5");
      await preferences.setString("unsplash_access_key", "secret");
      await preferences.setString("unsplash_author", "someone");
      await preferences.setString("custom_banner_com.example", "/data/banner.png");

      expect(backupService.exportSettings(), {"app_caption_font_size": 16.0, "accent_color": "00BFA5"});
    });

    test("applies typed values and notifies listeners", () async {
      var notified = 0;
      settingsService.addListener(() => notified++);

      final unknown = await backupService.applySettings({
        "app_caption_font_size": "18",
        "app_caption_visibility": "focused",
        "show_category_titles": "true",
        "brightness_day": 40,
        "not_a_setting": 1,
      });

      expect(unknown, ["not_a_setting"]);
      expect(settingsService.appCaptionStyle.fontSize, 18);
      expect(settingsService.showCategoryTitles, isTrue);
      expect(preferences.getInt("brightness_day"), 40);
      // The legacy on/off switch follows the caption visibility.
      expect(preferences.getBool("show_app_names_below_icons"), isTrue);
      expect(notified, greaterThan(0));
    });

    test("writes nothing when one value is invalid", () async {
      await expectLater(
        backupService.applySettings({"show_category_titles": true, "accent_color": "purple"}),
        throwsFormatException,
      );

      expect(preferences.containsKey("show_category_titles"), isFalse);
      expect(preferences.containsKey("accent_color"), isFalse);
    });

    test("null resets a setting to its default", () async {
      await preferences.setBool("show_time_in_status_bar", false);

      await backupService.applySettings({"show_time_in_status_bar": null});

      expect(settingsService.showTimeInStatusBar, isTrue);
    });
  });

  group("restore", () {
    test("replaces settings, keeping secrets, and restores the layout", () async {
      await preferences.setBool("show_category_titles", true);
      await preferences.setString("unsplash_access_key", "secret");

      final summary = await backupService.restore({
        "format": kBackupFormat,
        "version": kBackupVersion,
        "settings": {"accent_color": "FF6D00"},
        "layout": _layout,
      });

      expect(settingsService.accentColorHex, "FF6D00");
      expect(preferences.containsKey("show_category_titles"), isFalse);
      expect(settingsService.unsplashAccessKey, "secret");
      verify(appsService.restoreLayout(_layout));
      expect(summary.settings, isTrue);
      expect(summary.layout, isTrue);
      expect(summary.skippedApps, 2);
    });

    test("restores only the parts a backup has", () async {
      await preferences.setBool("show_category_titles", true);

      final summary = await backupService.restore({"layout": _layout});

      expect(settingsService.showCategoryTitles, isTrue);
      expect(summary.settings, isFalse);
    });

    test("rejects other files and newer versions without changing anything", () async {
      await expectLater(backupService.restore({"format": "something-else", "settings": {}}), throwsFormatException);
      await expectLater(backupService.restore({"version": kBackupVersion + 1, "settings": {}}), throwsFormatException);
      await expectLater(backupService.restore({"format": kBackupFormat}), throwsFormatException);
      await expectLater(
        backupService.restore({"settings": {"accent_color": "nope"}, "layout": _layout}),
        throwsFormatException,
      );
      verifyNever(appsService.restoreLayout(any));
    });

    test("waits for the launcher before restoring a layout", () async {
      when(appsService.initialized).thenReturn(false);

      await expectLater(backupService.restore({"layout": _layout}), throwsStateError);
    });
  });

  group("files", () {
    test("exports a backup that restores what it saved", () async {
      await preferences.setString("app_icon_variant", "monochrome");

      final file = await backupService.export();
      final backup = jsonDecode(file.readAsStringSync());

      expect(file.parent.path, directory.path);
      expect(backup["format"], kBackupFormat);
      expect(backup["settings"], {"app_icon_variant": "monochrome"});
      expect(backup["layout"], _layout);

      await preferences.setString("app_icon_variant", "foreground");
      await backupService.restoreFile(file);

      expect(settingsService.appIconStyle.variant.name, "monochrome");
    });

    test("saves the current state before restoring", () async {
      await preferences.setString("accent_color", "2979FF");

      await backupService.restoreText(jsonEncode({"settings": {"accent_color": "FFFFFF"}}));

      final undo = File("${directory.path}/$kBeforeRestoreFileName");
      expect(jsonDecode(undo.readAsStringSync())["settings"], {"accent_color": "2979FF"});
      expect((await backupService.listBackups()).map((file) => file.path), [undo.path]);
    });

    test("reports text that is not JSON", () async {
      await expectLater(backupService.restoreText("{oops"), throwsFormatException);
    });

    test("names files by date", () {
      expect(BackupService.fileName(DateTime(2026, 3, 7, 9, 5, 2)), "arc-launcher-2026-03-07-090502.json");
    });
  });
}
