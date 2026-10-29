import 'dart:io';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// User supplied caption fonts.
///
/// Fonts are .ttf/.otf files kept in the app's external files directory
/// (`Android/data/<package>/files/fonts`), which needs no storage permission
/// and can be filled with `adb push` or imported through a file manager.
/// A font is referenced in settings by a key made of [filePrefix] and its
/// file name, and registered with the engine under its own family name.
abstract final class CustomFonts {
  static const String filePrefix = 'file:';
  static const String _familyPrefix = 'arc_custom_font_';

  static final Map<String, Future<bool>> _loads = {};
  static Directory? _directory;

  static bool isCustom(String font) => font.startsWith(filePrefix);

  static String keyFor(File file) => '$filePrefix${p.basename(file.path)}';

  static String displayName(String font) => p.basenameWithoutExtension(font.substring(filePrefix.length));

  /// The family to put in a [TextStyle]; null for the default font.
  static String? familyFor(String font) {
    if (font.isEmpty) {
      return null;
    }
    if (isCustom(font)) {
      return '$_familyPrefix${font.substring(filePrefix.length)}';
    }
    return font;
  }

  static Future<Directory> directory() async {
    if (_directory != null) {
      return _directory!;
    }
    Directory? base;
    try {
      base = await getExternalStorageDirectory();
    } catch (_) {
      base = null;
    }
    base ??= await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(base.path, 'fonts'));
    await directory.create(recursive: true);
    return _directory = directory;
  }

  static Future<List<String>> list() async {
    try {
      final dir = await directory();
      final fonts = await dir
          .list()
          .where((entity) => entity is File && _isFontFile(entity.path))
          .map((entity) => keyFor(entity as File))
          .toList();
      fonts.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return fonts;
    } catch (_) {
      return const [];
    }
  }

  /// Opens the system file picker and copies the chosen font into [directory].
  /// Returns the key of the imported font, or null if nothing was imported.
  static Future<String?> import(FLauncherChannel channel) async {
    final dir = await directory();
    final path = await channel.pickFontFile(dir.path);
    if (path == null) {
      return null;
    }
    final key = keyFor(File(path));
    // A font replaced under the same name has to be registered again.
    _loads.remove(key);
    return await ensureLoaded(key) ? key : null;
  }

  /// Registers [font] with the engine if it is a custom font. Text already laid
  /// out with its family is re-laid out by the engine once it is loaded.
  static Future<bool> ensureLoaded(String font) {
    if (!isCustom(font)) {
      return Future.value(true);
    }
    return _loads.putIfAbsent(font, () async {
      try {
        final file = File(p.join((await directory()).path, font.substring(filePrefix.length)));
        final bytes = await file.readAsBytes();
        final loader = FontLoader(familyFor(font)!)..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
        return true;
      } catch (_) {
        _loads.remove(font);
        return false;
      }
    });
  }

  static bool _isFontFile(String path) {
    final extension = p.extension(path).toLowerCase();
    return extension == '.ttf' || extension == '.otf';
  }
}
