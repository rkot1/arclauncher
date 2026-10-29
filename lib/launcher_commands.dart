import 'dart:convert';
import 'dart:io';

import 'package:flauncher/models/setting_spec.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Answers `adb shell am broadcast -a <package>.COMMAND --es cmd <command> …`, which MainActivity passes on,
/// so settings can be tuned from a computer while the launcher shows the result. See the README.
class LauncherCommands {
  static const _channel = MethodChannel('me.efesser.flauncher/commands');

  /// How long next-photo waits for the photo, safely within the time Android gives a broadcast.
  static const _nextPhotoWait = Duration(seconds: 8);

  final BackupService _backupService;
  final WallpaperService _wallpaperService;

  LauncherCommands(this._backupService, this._wallpaperService);

  void attach() => _channel.setMethodCallHandler(_onMethodCall);

  void detach() => _channel.setMethodCallHandler(null);

  Future<Map<String, Object>> _onMethodCall(MethodCall call) async {
    if (call.method != "run") {
      throw MissingPluginException();
    }
    final (ok, output) = await run(Map<String, String?>.from(call.arguments as Map));
    return {"ok": ok, "output": output};
  }

  /// Runs the command in [arguments] (the broadcast's extras); answers whether it worked and the text to print.
  Future<(bool, String)> run(Map<String, String?> arguments) async {
    try {
      return (true, await _run(arguments["cmd"]?.trim() ?? "help", arguments));
    } on FormatException catch (e) {
      return (false, "error: ${e.message}");
    } on StateError catch (e) {
      return (false, "error: ${e.message}");
    } on FileSystemException catch (e) {
      return (false, "error: ${e.message}${e.path != null ? " (${e.path})" : ""}");
    }
  }

  Future<String> _run(String command, Map<String, String?> arguments) async {
    String argument(String name) =>
        arguments[name] ?? (throw FormatException("$command needs --es $name, run help for usage"));

    switch (command) {
      case "help":
        return _help();
      case "list":
        return _encode({for (final spec in _backupService.specs.values) spec.key: _shown(spec)});
      case "get":
        return _encode(_shown(_spec(argument("key"))));
      case "set":
        final json = arguments["json"];
        final Map<String, Object?> values = json != null ? _decodeObject(json) : {argument("key"): argument("value")};
        for (final key in values.keys) {
          _spec(key);
        }
        await _backupService.applySettings(values);
        return _encode({for (final key in values.keys) key: _shown(_spec(key))});
      case "reset":
        final spec = _spec(argument("key"));
        await _backupService.applySettings({spec.key: null});
        return "ok";
      case "folder":
        return (await _backupService.directory()).path;
      case "export":
        return (await _backupService.export(path: arguments["path"])).path;
      case "import":
        final json = arguments["json"];
        final summary = json != null
            ? await _backupService.restoreText(json)
            : await _backupService.restoreFile(File(argument("path")));
        return summary.toString();
      case "dump":
        return _backupService.encodeBackup();
      case "next-photo":
        return _nextPhoto();
      default:
        throw FormatException("Unknown command $command, run help for the list");
    }
  }

  Future<String> _nextPhoto() async {
    final shown = await _wallpaperService
        .nextSlideshowPhoto()
        .then<bool?>((shown) => shown)
        .timeout(_nextPhotoWait, onTimeout: () => null);
    return switch (shown) {
      true => "showing a photo by ${_wallpaperService.slideshowAuthor ?? "an unknown author"}",
      false => throw StateError("could not load a photo: check the access key and the connection, or try again later"),
      null => "still loading, the photo shows when it arrives",
    };
  }

  SettingSpec _spec(String key) =>
      _backupService.specs[key] ?? (throw FormatException("Unknown setting $key, run help for the list"));

  /// The stored value, null for the default, and only whether a secret is set.
  Object? _shown(SettingSpec spec) {
    final value = _backupService.valueOf(spec.key);
    return spec.secret && value != null ? "(set)" : value;
  }

  static Map<String, Object?> _decodeObject(String json) {
    final Object? value;
    try {
      value = jsonDecode(json);
    } on FormatException catch (e) {
      throw FormatException("json is not valid JSON: ${e.message}");
    }
    if (value is! Map<String, dynamic>) {
      throw const FormatException("json must be an object of settings");
    }
    return value;
  }

  static String _encode(Object? value) => const JsonEncoder.withIndent("  ").convert(value);

  Future<String> _help() async {
    String package;
    try {
      package = (await PackageInfo.fromPlatform()).packageName;
    } catch (_) {
      package = "com.omeda.arc";
    }
    final specs = _backupService.specs.values.map((spec) => "  ${spec.describe()}").join("\n");
    return '''
Usage: adb shell am broadcast -a $package.COMMAND -p $package --es cmd <command> [--es <name> <value>]...

Commands:
  help                             this text
  list                             every setting as JSON, null meaning the default
  get --es key <key>               one setting
  set --es key <key> --es value <value>
  set --es json '{"<key>": <value>, ...}'
  reset --es key <key>             back to the default
  folder                           the backups folder, created if missing
  export [--es path <file>]        save a backup (default: ${(await _backupService.directory()).path})
  import --es path <file>          restore a backup, or --es json '<backup>'
  dump                             print a backup
  next-photo                       show the next Unsplash slideshow photo now

Settings:
$specs''';
  }
}
