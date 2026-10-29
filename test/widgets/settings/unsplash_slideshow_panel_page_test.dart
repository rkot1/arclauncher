import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/settings/unsplash_slideshow_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../mocks.mocks.dart';

void main() {
  late MockSettingsService settingsService;
  late MockWallpaperService wallpaperService;

  setUp(() {
    settingsService = MockSettingsService();
    when(settingsService.unsplashSlideshowEnabled).thenReturn(true);
    when(settingsService.unsplashAccessKey).thenReturn("key-1234");
    when(settingsService.unsplashIntervalMinutes).thenReturn(30);
    wallpaperService = MockWallpaperService();
  });

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(value: settingsService),
            ChangeNotifierProvider<WallpaperService>.value(value: wallpaperService),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: UnsplashSlideshowPanelPage()),
          ),
        ),
      );

  testWidgets("next photo shows progress, then says the photo changed", (tester) async {
    final photo = Completer<bool>();
    when(wallpaperService.nextSlideshowPhoto()).thenAnswer((_) => photo.future);
    await pumpPage(tester);

    await tester.tap(find.text("Next photo now"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("Loading the next photo…"), findsOneWidget);

    photo.complete(true);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text("Loading the next photo…"), findsNothing);
    expect(find.text("New photo on the home screen"), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text("New photo on the home screen"), findsOneWidget, reason: "it stays up for 4 seconds");
  });

  testWidgets("next photo says when the photo could not be loaded", (tester) async {
    when(wallpaperService.nextSlideshowPhoto()).thenAnswer((_) async => false);
    await pumpPage(tester);

    await tester.tap(find.text("Next photo now"));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.textContaining("Couldn't load a photo"), findsOneWidget);
  });

  testWidgets("next photo is offered only while the slideshow is on", (tester) async {
    when(settingsService.unsplashSlideshowEnabled).thenReturn(false);
    await pumpPage(tester);

    expect(find.text("Next photo now"), findsNothing);
  });
}
