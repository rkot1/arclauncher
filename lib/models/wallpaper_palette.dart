import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Width the wallpaper is decoded at to pick its colours; plenty for a palette and cheap to quantize.
const int _thumbnailWidth = 64;

/// The main colours of a wallpaper, for app cards that blend with it.
@immutable
class WallpaperPalette {
  /// The colour covering most of the wallpaper.
  final Color main;

  /// Its most characterful colour, chosen for chroma as well as coverage; [main] on a grey wallpaper.
  final Color accent;

  const WallpaperPalette(this.main, this.accent);

  /// Used until the wallpaper colours are known, and for video wallpapers.
  static const WallpaperPalette fallback = WallpaperPalette(Color(0xFF2C2C31), Color(0xFF2C2C31));

  /// Picks the colours of [pixels], given as ARGB; transparent pixels are ignored.
  static Future<WallpaperPalette> fromPixels(Iterable<int> pixels) async {
    final opaque = pixels.where((argb) => argb >>> 24 == 0xFF).toList();
    if (opaque.isEmpty) {
      return fallback;
    }
    final counts = (await QuantizerCelebi().quantize(opaque, 24)).colorToCount;
    final main = counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    final accent = Score.score(counts, desired: 1, fallbackColorARGB: main).first;
    return WallpaperPalette(Color(main), Color(accent));
  }

  /// Picks the colours of a gradient wallpaper.
  static Future<WallpaperPalette> fromColors(List<Color> colors) =>
      fromPixels([for (final color in colors) color.toARGB32()]);

  /// Picks the colours of [image], decoded at a thumbnail size; null when it cannot be decoded.
  static Future<WallpaperPalette?> fromImage(ImageProvider image) async {
    final decoded = Completer<ui.Image>();
    final listener = ImageStreamListener(
      (info, _) => decoded.isCompleted ? info.dispose() : decoded.complete(info.image),
      onError: (error, stackTrace) => decoded.isCompleted ? null : decoded.completeError(error, stackTrace),
    );
    ImageStream? stream;
    try {
      stream = ResizeImage(image, width: _thumbnailWidth).resolve(ImageConfiguration.empty)..addListener(listener);
      final thumbnail = await decoded.future;
      final bytes = await thumbnail.toByteData();
      thumbnail.dispose();
      if (bytes == null) {
        return null;
      }
      return await fromPixels([
        for (var i = 0; i + 3 < bytes.lengthInBytes; i += 4)
          bytes.getUint8(i + 3) << 24 | bytes.getUint8(i) << 16 | bytes.getUint8(i + 1) << 8 | bytes.getUint8(i + 2),
      ]);
    } catch (e) {
      debugPrint("Wallpaper palette: $e");
      return null;
    } finally {
      stream?.removeListener(listener);
    }
  }

  /// App card gradient, from the accent at the top left into the main colour, toned down so icons
  /// and captions stand out.
  List<Color> get cardColors => [_tone(accent, 32), _tone(main, 17)];

  static Color _tone(Color color, double tone) {
    final hct = Hct.fromInt(color.toARGB32());
    return Color(Hct.from(hct.hue, min(hct.chroma, 40), tone).toInt());
  }

  @override
  bool operator ==(Object other) => other is WallpaperPalette && other.main == main && other.accent == accent;

  @override
  int get hashCode => Object.hash(main, accent);
}
