import 'dart:convert';
import 'dart:io';

import 'package:flauncher/custom_fonts.dart';
import 'package:flauncher/models/setting_spec.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBackupFormat = "arc-launcher-backup";
const int kBackupVersion = 1;

/// Written just before every restore, so restoring it undoes the last one.
const String kBeforeRestoreFileName = "arc-launcher-before-restore.json";

/// What a restore changed.
class RestoreSummary {
  final bool settings;
  final bool layout;

  /// Apps in the backup that are not installed here.
  final int skippedApps;

  /// Installed apps the backup does not mention, put in "All Apps".
  final int addedApps;

  /// Keys in the backup that are not settings of this version.
  final List<String> unknownSettings;

  const RestoreSummary({
    required this.settings,
    required this.layout,
    this.skippedApps = 0,
    this.addedApps = 0,
    this.unknownSettings = const [],
  });

  @override
  String toString() => [
        "restored ${[if (settings) "settings", if (layout) "layout"].join(" and ")}",
        if (skippedApps > 0) "skipped $skippedApps apps that are not installed",
        if (addedApps > 0) "added $addedApps unlisted apps to All Apps",
        if (unknownSettings.isNotEmpty) "ignored unknown settings ${unknownSettings.join(", ")}",
      ].join("; ");
}

/// Saves settings and the launcher layout to one JSON file, and restores them from it.
class BackupService {
  final SharedPreferences _preferences;
  final SettingsService _settingsService;
  final BrightnessService _brightnessService;
  final AppsService _appsService;
  final Future<Directory> Function() _directory;

  /// Every setting a backup carries, by key.
  final Map<String, SettingSpec> specs = {
    for (final spec in [...settingSpecs, ...brightnessSettingSpecs]) spec.key: spec,
  };

  BackupService(
    this._preferences,
    this._settingsService,
    this._brightnessService,
    this._appsService, {
    Future<Directory> Function()? directory,
  }) : _directory = directory ?? _defaultDirectory;

  /// Where backups are saved and adb can drop them: `Android/data/<package>/files/backups`.
  Future<Directory> directory() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return directory;
  }

  static Future<Directory> _defaultDirectory() async {
    Directory? base;
    try {
      base = await getExternalStorageDirectory();
    } catch (_) {
      base = null;
    }
    base ??= await getApplicationDocumentsDirectory();
    return Directory(p.join(base.path, "backups"));
  }

  /// The stored value of [key], or null while it is at its default.
  Object? valueOf(String key) => _preferences.get(key);

  /// Settings changed from their defaults, by key. Secrets stay out.
  Map<String, Object> exportSettings() => {
        for (final spec in specs.values)
          if (!spec.secret && _preferences.get(spec.key) != null) spec.key: _preferences.get(spec.key)!,
      };

  Future<Map<String, Object?>> createBackup() async => {
        "format": kBackupFormat,
        "version": kBackupVersion,
        "appVersion": await _appVersion(),
        "createdAt": DateTime.now().toUtc().toIso8601String(),
        "settings": exportSettings(),
        "layout": await _appsService.exportLayout(),
      };

  Future<String> encodeBackup() async => const JsonEncoder.withIndent("  ").convert(await createBackup());

  /// Changes the given settings, where null resets one to its default. With [replace], settings missing from
  /// [values] go back to their defaults too, secrets excepted.
  ///
  /// Every value is checked first, so a bad one changes nothing. Returns the keys that are not settings.
  Future<List<String>> applySettings(Map<String, Object?> values, {bool replace = false}) async {
    final (changes, unknown) = _prepareSettings(values, replace: replace);
    await _commitSettings(changes);
    return unknown;
  }

  /// Restores [backup], as [createBackup] writes it. Settings it does not list go back to their defaults.
  ///
  /// Throws a [FormatException] without changing anything when the backup is malformed.
  Future<RestoreSummary> restore(Map<String, dynamic> backup) async {
    if (backup["format"] != null && backup["format"] != kBackupFormat) {
      throw const FormatException("This is not an Arc Launcher backup");
    }
    final version = backup["version"];
    if (version is num && version > kBackupVersion) {
      throw const FormatException("This backup was made by a newer version of Arc Launcher");
    }
    final settings = backup["settings"];
    final layout = backup["layout"];
    if (settings is! Map<String, dynamic>? || layout is! Map<String, dynamic>?) {
      throw const FormatException("settings and layout must be JSON objects");
    }
    if (settings == null && layout == null) {
      throw const FormatException("The backup has neither settings nor a layout");
    }
    if (layout != null && !_appsService.initialized) {
      throw StateError("The launcher is still starting, try again in a moment");
    }

    // Settings are checked before the layout changes, and the layout before settings are written.
    final (changes, unknown) = settings != null ? _prepareSettings(settings, replace: true) : (null, <String>[]);
    final layoutResult = layout != null ? await _appsService.restoreLayout(layout) : null;
    if (changes != null) {
      await _commitSettings(changes);
    }

    return RestoreSummary(
      settings: changes != null,
      layout: layoutResult != null,
      skippedApps: layoutResult?.skippedApps ?? 0,
      addedApps: layoutResult?.addedApps ?? 0,
      unknownSettings: unknown,
    );
  }

  /// Restores a backup from its JSON text, after saving the current state as [kBeforeRestoreFileName].
  Future<RestoreSummary> restoreText(String text) async {
    final Object? backup;
    try {
      backup = jsonDecode(text);
    } on FormatException catch (e) {
      throw FormatException("The file is not valid JSON: ${e.message}");
    }
    if (backup is! Map<String, dynamic>) {
      throw const FormatException("This is not an Arc Launcher backup");
    }
    await _saveTo(File(p.join((await directory()).path, kBeforeRestoreFileName)));
    return restore(backup);
  }

  Future<RestoreSummary> restoreFile(File file) async => restoreText(await file.readAsString());

  /// Saves a backup to [path], or to a new dated file in [directory].
  Future<File> export({String? path}) async {
    final file = File(path ?? p.join((await directory()).path, fileName(DateTime.now())));
    await _saveTo(file);
    return file;
  }

  /// The backups in [directory], newest first.
  Future<List<File>> listBackups() async {
    final files = await (await directory())
        .list()
        .where((entity) => entity is File && entity.path.toLowerCase().endsWith(".json"))
        .cast<File>()
        .toList();
    final modified = {for (final file in files) file.path: await file.lastModified()};
    files.sort((a, b) => modified[b.path]!.compareTo(modified[a.path]!));
    return files;
  }

  static String fileName(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, "0");
    return "arc-launcher-${time.year}-${twoDigits(time.month)}-${twoDigits(time.day)}"
        "-${twoDigits(time.hour)}${twoDigits(time.minute)}${twoDigits(time.second)}.json";
  }

  (Map<SettingSpec, Object?>, List<String>) _prepareSettings(Map<String, Object?> values, {required bool replace}) {
    final changes = <SettingSpec, Object?>{};
    final unknown = <String>[];
    for (final MapEntry(:key, :value) in values.entries) {
      final spec = specs[key];
      if (spec == null) {
        unknown.add(key);
      } else {
        changes[spec] = value == null ? null : spec.coerce(value);
      }
    }
    if (replace) {
      for (final spec in specs.values) {
        if (!spec.secret && !values.containsKey(spec.key)) {
          changes[spec] = null;
        }
      }
    }
    return (changes, unknown);
  }

  Future<void> _commitSettings(Map<SettingSpec, Object?> changes) async {
    for (final MapEntry(key: spec, :value) in changes.entries) {
      await switch (value) {
        null => _preferences.remove(spec.key),
        bool value => _preferences.setBool(spec.key, value),
        int value => _preferences.setInt(spec.key, value),
        double value => _preferences.setDouble(spec.key, value),
        String value => _preferences.setString(spec.key, value),
        List<String> value => _preferences.setStringList(spec.key, value),
        _ => throw ArgumentError.value(value, spec.key),
      };
    }
    await _settingsService.reload();
    await _brightnessService.reload();
    await CustomFonts.ensureLoaded(_settingsService.appCaptionStyle.font);
  }

  Future<void> _saveTo(File file) async {
    final text = await encodeBackup();
    await file.parent.create(recursive: true);
    await file.writeAsString(text, flush: true);
  }

  static Future<String?> _appVersion() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      return null;
    }
  }
}
