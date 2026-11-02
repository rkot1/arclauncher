import 'dart:convert';
import 'dart:io';

import 'package:flauncher/launcher_commands.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late SettingsService settingsService;
  late MockAppsService appsService;
  late Directory directory;
  late LauncherCommands commands;

  setUp(() async {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    SharedPreferences.resetStatic();
    preferences = await SharedPreferences.getInstance();
    settingsService = SettingsService(preferences);
    appsService = MockAppsService();
    when(appsService.initialized).thenReturn(true);
    when(appsService.exportLayout()).thenAnswer((_) async => {"sections": [], "hiddenApps": []});
    when(appsService.restoreLayout(any)).thenAnswer((_) async => (skippedApps: 0, addedApps: 0));
    directory = Directory.systemTemp.createTempSync("arc_commands_test");
    addTearDown(() => directory.deleteSync(recursive: true));
    commands = LauncherCommands(BackupService(
      preferences,
      settingsService,
      BrightnessService(preferences),
      appsService,
      directory: () async => directory,
    ));
  });

  test("set changes one setting live and prints it", () async {
    final (ok, output) =
        await commands.run({"cmd": "set", "key": "app_caption_background", "value": "pill"});

    expect(ok, isTrue);
    expect(jsonDecode(output), {"app_caption_background": "pill"});
    expect(settingsService.appCaptionStyle.background.name, "pill");
  });

  test("set takes several settings as JSON", () async {
    final (ok, _) = await commands.run({
      "cmd": "set",
      "json": '{"app_caption_font_size": 15, "app_icon_size": "large"}',
    });

    expect(ok, isTrue);
    expect(settingsService.appCaptionStyle.fontSize, 15);
    expect(settingsService.appIconStyle.size.name, "large");
  });

  test("bad values and unknown keys fail without changes", () async {
    final (badOk, badOutput) = await commands.run({"cmd": "set", "key": "app_icon_size", "value": "huge"});
    expect(badOk, isFalse);
    expect(badOutput, startsWith("error: app_icon_size expects one of"));

    final (unknownOk, unknownOutput) = await commands.run({
      "cmd": "set",
      "json": '{"accent_color": "FF6D00", "acent_colour": "FF6D00"}',
    });
    expect(unknownOk, isFalse);
    expect(unknownOutput, contains("acent_colour"));
    expect(preferences.containsKey("accent_color"), isFalse);

    final (missingOk, missingOutput) = await commands.run({"cmd": "get"});
    expect(missingOk, isFalse);
    expect(missingOutput, contains("--es key"));
  });

  test("get, list and reset", () async {
    await commands.run({"cmd": "set", "key": "show_category_titles", "value": "true"});
    await commands.run({"cmd": "set", "key": "reddit_client_secret", "value": "hunter2"});

    expect((await commands.run({"cmd": "get", "key": "show_category_titles"})).$2, "true");

    final list = jsonDecode((await commands.run({"cmd": "list"})).$2) as Map;
    expect(list["show_category_titles"], isTrue);
    expect(list["reddit_client_secret"], "(set)");
    expect(list["accent_color"], isNull);

    expect((await commands.run({"cmd": "reset", "key": "show_category_titles"})).$1, isTrue);
    expect(settingsService.showCategoryTitles, isFalse);
  });

  test("export and import go through backup files", () async {
    await commands.run({"cmd": "set", "key": "accent_color", "value": "00BFA5"});

    final (exportOk, path) = await commands.run({"cmd": "export"});
    expect(exportOk, isTrue);
    expect(File(path).existsSync(), isTrue);

    await commands.run({"cmd": "set", "key": "accent_color", "value": "FFFFFF"});
    final (importOk, summary) = await commands.run({"cmd": "import", "path": path});

    expect(importOk, isTrue);
    expect(summary, "restored settings and layout");
    expect(settingsService.accentColorHex, "00BFA5");

    final (missingOk, missingOutput) = await commands.run({"cmd": "import", "path": "${directory.path}/nope.json"});
    expect(missingOk, isFalse);
    expect(missingOutput, startsWith("error:"));
  });

  test("folder prints the backups folder and creates it", () async {
    directory.deleteSync(recursive: true);

    final (ok, output) = await commands.run({"cmd": "folder"});

    expect(ok, isTrue);
    expect(output, directory.path);
    expect(directory.existsSync(), isTrue);
  });

  test("help lists commands and settings, unknown commands fail", () async {
    final (ok, help) = await commands.run({"cmd": "help"});
    expect(ok, isTrue);
    expect(help, contains("set --es key <key> --es value <value>"));
    expect(help, contains("app_caption_box_shadow: none|soft|strong|glow"));

    final (unknownOk, unknownOutput) = await commands.run({"cmd": "frobnicate"});
    expect(unknownOk, isFalse);
    expect(unknownOutput, contains("frobnicate"));
  });
}
