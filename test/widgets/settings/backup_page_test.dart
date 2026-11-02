import 'dart:io';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/backup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../mocks.mocks.dart';

void main() {
  late SharedPreferences preferences;
  late Directory directory;
  late BackupService backupService;

  setUp(() async {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    SharedPreferences.resetStatic();
    preferences = await SharedPreferences.getInstance();
    final appsService = MockAppsService();
    when(appsService.initialized).thenReturn(true);
    when(appsService.exportLayout()).thenAnswer((_) async => {"sections": [], "hiddenApps": []});
    directory = Directory.systemTemp.createTempSync("arc_backup_page_test");
    addTearDown(() => directory.deleteSync(recursive: true));
    backupService = BackupService(
      preferences,
      SettingsService(preferences),
      BrightnessService(preferences),
      appsService,
      directory: () async => directory,
    );
  });

  /// Lets real file operations finish, pumping frames between them.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump();
    }
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider.value(
        value: backupService,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: BackupPage()),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets("export saves a backup and lists it", (tester) async {
    await pumpPage(tester);
    expect(find.text("No backups yet"), findsOneWidget);

    await tester.tap(find.text("Export settings & layout"));
    await settle(tester);

    expect(find.textContaining("Saved to ${directory.path}"), findsOneWidget);
    expect(find.textContaining(RegExp(r"^arc-launcher-\d{4}-")), findsOneWidget);
    expect(find.text("No backups yet"), findsNothing);
  });

  testWidgets("restoring a listed backup asks first", (tester) async {
    await preferences.setString("accent_color", "00BFA5");
    await tester.runAsync(() => backupService.export(path: "${directory.path}/mine.json"));
    await preferences.setString("accent_color", "FFFFFF");
    await pumpPage(tester);

    await tester.tap(find.text("mine.json"));
    await tester.pumpAndSettle();
    expect(find.text("Restore this backup?"), findsOneWidget);

    await tester.tap(find.text("Restore"));
    await settle(tester);

    expect(find.text("Backup restored"), findsOneWidget);
    expect(preferences.getString("accent_color"), "00BFA5");
    expect(find.text(kBeforeRestoreFileName), findsOneWidget);
  });
}
