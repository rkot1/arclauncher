import 'package:flauncher/models/app_card_style.dart';
import 'package:flauncher/models/wallpaper_palette.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/app_icon_face.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.mocks.dart';

void main() {
  const style = AppIconStyle(mode: AppCardImageMode.icon, background: AppCardBackground.wallpaper);

  Future<void> pumpBackground(WidgetTester tester, WallpaperService wallpaperService) => tester.pumpWidget(
        ChangeNotifierProvider<WallpaperService>.value(
          value: wallpaperService,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(width: 160, height: 90, child: AppCardBackgroundView(style: style)),
          ),
        ),
      );

  List<Color> cardColors(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    return ((container.decoration! as BoxDecoration).gradient! as LinearGradient).colors;
  }

  testWidgets("wallpaper background uses the wallpaper colours", (tester) async {
    const palette = WallpaperPalette(Color(0xFF2457C5), Color(0xFFE8701A));
    final wallpaperService = MockWallpaperService();
    when(wallpaperService.palette).thenReturn(palette);

    await pumpBackground(tester, wallpaperService);

    expect(cardColors(tester), palette.cardColors);
  });

  testWidgets("wallpaper background falls back to graphite until the colours are known", (tester) async {
    final wallpaperService = MockWallpaperService();
    when(wallpaperService.palette).thenReturn(null);

    await pumpBackground(tester, wallpaperService);

    expect(cardColors(tester), WallpaperPalette.fallback.cardColors);
  });
}
