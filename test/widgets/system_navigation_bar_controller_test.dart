import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/system_navigation_bar_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../mocks.mocks.dart';

void main() {
  late MockFLauncherChannel channel;
  late SettingsService settingsService;

  setUp(() async {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    SharedPreferences.resetStatic();
    settingsService = SettingsService(await SharedPreferences.getInstance());
    channel = MockFLauncherChannel();
    when(channel.setNavigationBarMode(any)).thenAnswer((_) async {});
    when(channel.setNavigationBarRevealed(any)).thenAnswer((_) async {});
  });

  Future<TestGesture> pumpController(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settingsService,
        child: MaterialApp(
          builder: (context, child) => SystemNavigationBarController(channel: channel, child: child!),
          home: const Focus(autofocus: true, child: SizedBox.expand()),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(100, 100));
    addTearDown(mouse.removePointer);
    return mouse;
  }

  testWidgets("leaves the window alone while the bar is visible", (tester) async {
    final mouse = await pumpController(tester);
    final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;

    await mouse.moveTo(Offset(100, height - 1));
    await tester.pump();

    verifyNever(channel.setNavigationBarMode(any));
    verifyNever(channel.setNavigationBarRevealed(any));
  });

  testWidgets("reveals the bar at the bottom edge and hides it above", (tester) async {
    await settingsService.setNavigationBarMode(SystemNavigationBarMode.bottomEdge);
    final mouse = await pumpController(tester);
    final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    verify(channel.setNavigationBarMode("bottomEdge")).called(1);

    await mouse.moveTo(Offset(100, height - 1));
    await tester.pump();
    verify(channel.setNavigationBarRevealed(true)).called(1);

    // Still within the area the bar covers.
    await mouse.moveTo(Offset(100, height - 40));
    await tester.pump();
    verifyNever(channel.setNavigationBarRevealed(false));

    await mouse.moveTo(Offset(100, height / 2));
    await tester.pump();
    verify(channel.setNavigationBarRevealed(false)).called(1);
  });

  testWidgets("hides a revealed bar on key press", (tester) async {
    await settingsService.setNavigationBarMode(SystemNavigationBarMode.bottomEdge);
    final mouse = await pumpController(tester);
    final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;

    await mouse.moveTo(Offset(100, height - 1));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    verify(channel.setNavigationBarRevealed(false)).called(1);
  });

  testWidgets("does not react to the bottom edge when the bar is simply hidden", (tester) async {
    await settingsService.setNavigationBarMode(SystemNavigationBarMode.hidden);
    final mouse = await pumpController(tester);
    final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    verify(channel.setNavigationBarMode("hidden")).called(1);

    await mouse.moveTo(Offset(100, height - 1));
    await tester.pump();

    verifyNever(channel.setNavigationBarRevealed(any));
  });
}
