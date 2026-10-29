import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flauncher/models/wallpaper_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

const _grey = 0xFF707070;
const _orange = 0xFFE8701A;
const _blue = 0xFF2457C5;

List<int> _pixels(Map<int, int> counts) => [
      for (final MapEntry(key: argb, value: count) in counts.entries) ...List.filled(count, argb),
    ];

Matcher _hueNear(int argb) => predicate<Color>(
      (color) => MathUtils.differenceDegrees(Hct.fromInt(color.toARGB32()).hue, Hct.fromInt(argb).hue) < 10,
      "hue near ${argb.toRadixString(16)}",
    );

void main() {
  test("main is the colour covering most of the wallpaper, accent its most colourful one", () async {
    final palette = await WallpaperPalette.fromPixels(_pixels({_grey: 700, _orange: 300}));

    expect(palette.main, _hueNear(_grey));
    expect(Hct.fromInt(palette.main.toARGB32()).chroma, lessThan(5));
    expect(palette.accent, _hueNear(_orange));
  });

  test("a grey wallpaper keeps its own colour as the accent", () async {
    final palette = await WallpaperPalette.fromPixels(_pixels({_grey: 500, 0xFF303030: 500}));

    expect(palette.accent, palette.main);
  });

  test("transparent pixels are ignored", () async {
    expect(await WallpaperPalette.fromPixels(_pixels({0x00FFFFFF: 50})), WallpaperPalette.fallback);
    expect(
      (await WallpaperPalette.fromPixels(_pixels({0x80FF0000: 900, _blue: 100}))).main,
      _hueNear(_blue),
    );
  });

  test("gradient wallpapers use their own colours", () async {
    final palette = await WallpaperPalette.fromColors(const [Color(_blue), Color(_orange)]);

    expect([palette.main, palette.accent], everyElement(anyOf(_hueNear(_blue), _hueNear(_orange))));
  });

  test("card colours keep the hues, toned down", () {
    const palette = WallpaperPalette(Color(_blue), Color(_orange));
    final [top, bottom] = [for (final color in palette.cardColors) Hct.fromInt(color.toARGB32())];

    expect(top.tone, closeTo(32, 1));
    expect(bottom.tone, closeTo(17, 1));
    expect(top.chroma, lessThanOrEqualTo(41));
    expect(Color(top.toInt()), _hueNear(_orange));
    expect(Color(bottom.toInt()), _hueNear(_blue));
  });

  testWidgets("reads the colours of an image", (tester) async {
    final palette = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder)
        ..drawRect(const Rect.fromLTWH(0, 0, 160, 90), Paint()..color = const Color(_blue))
        ..drawRect(const Rect.fromLTWH(0, 60, 160, 30), Paint()..color = const Color(_orange));
      final image = await recorder.endRecording().toImage(160, 90);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return WallpaperPalette.fromImage(MemoryImage(png!.buffer.asUint8List()));
    });

    expect(palette, isNotNull);
    expect(palette!.main, _hueNear(_blue));
  });

  testWidgets("answers null for an image it cannot decode", (tester) async {
    final palette = await tester.runAsync(
      () => WallpaperPalette.fromImage(MemoryImage(Uint8List.fromList([1, 2, 3]))),
    );

    expect(palette, isNull);
  });
}
