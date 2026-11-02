import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/display_resolution_service.dart';
import 'package:flauncher/widgets/settings/display_resolution_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../fake_display_resolution_service.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, FakeDisplayResolutionService display) async {
    await tester.pumpWidget(
      Provider<DisplayResolutionService>.value(
        value: display,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DisplayResolutionPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("a confirmed resolution stays", (tester) async {
    final display = FakeDisplayResolutionService();
    await pumpPage(tester, display);
    expect(find.text("3840 × 2160, density 480"), findsOneWidget);

    await tester.tap(find.text("1080p"));
    await tester.pumpAndSettle();
    expect(find.text("Keep this resolution?"), findsOneWidget);
    expect(find.text("Going back to the previous resolution in 15 seconds."), findsOneWidget);

    await tester.tap(find.text("Keep"));
    await tester.pumpAndSettle();

    expect(find.text("Keep this resolution?"), findsNothing);
    expect([for (final resolution in display.applied) resolution.name], ["1080p"]);
    expect(display.width, 1920);
  });

  testWidgets("an unconfirmed resolution goes back when time is up", (tester) async {
    final display = FakeDisplayResolutionService(width: 2560, height: 1440, density: 320);
    await pumpPage(tester, display);

    await tester.tap(find.text("Native"));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 14));
    expect(find.text("Going back to the previous resolution in 1 second."), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text("Keep this resolution?"), findsNothing);
    expect([for (final resolution in display.applied) resolution.name], ["native", "1440p"]);
    expect((display.width, display.height, display.density), (2560, 1440, 320));
  });

  testWidgets("a size set elsewhere shows as custom and comes back on revert", (tester) async {
    final display = FakeDisplayResolutionService(width: 2560, height: 1440);
    await pumpPage(tester, display);
    expect(find.text("Custom"), findsOneWidget);

    await tester.tap(find.text("1440p"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Revert"));
    await tester.pumpAndSettle();

    expect([for (final resolution in display.applied) resolution.name], ["1440p", "custom"]);
    expect((display.width, display.height, display.density), (2560, 1440, 480));
  });

  testWidgets("without the permission the choices are off and the grant command shows", (tester) async {
    PackageInfo.setMockInitialValues(
      appName: "Arc Launcher",
      packageName: "com.omeda.arc",
      version: "1.2.0",
      buildNumber: "1",
      buildSignature: "",
    );
    final display = FakeDisplayResolutionService(canChange: false);
    await pumpPage(tester, display);

    expect(
      find.textContaining("adb shell pm grant com.omeda.arc android.permission.WRITE_SECURE_SETTINGS"),
      findsOneWidget,
    );

    await tester.tap(find.text("1080p"));
    await tester.pumpAndSettle();

    expect(find.text("Keep this resolution?"), findsNothing);
    expect(display.applied, isEmpty);
  });

  testWidgets("a build that can't reach the calls says so instead of asking for the permission", (tester) async {
    final display = FakeDisplayResolutionService(available: false, canChange: false);
    await pumpPage(tester, display);

    expect(find.textContaining("can't change the resolution on this device"), findsOneWidget);
    expect(find.textContaining("pm grant"), findsNothing);

    await tester.tap(find.text("1080p"));
    await tester.pumpAndSettle();
    expect(display.applied, isEmpty);
  });
}
