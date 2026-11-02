import 'dart:io';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

/// Exports settings and the layout to a JSON file, and restores them from one.
class BackupPage extends StatefulWidget {
  static const String routeName = "backup_panel";

  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  late final BackupService _service = Provider.of(context, listen: false);
  final FLauncherChannel _channel = FLauncherChannel();

  List<(File, DateTime)> _backups = const [];
  String? _directory;
  String? _package;
  String? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final directory = await _service.directory();
    final backups = [for (final file in await _service.listBackups()) (file, await file.lastModified())];
    String? package;
    try {
      package = (await PackageInfo.fromPlatform()).packageName;
    } catch (_) {
      package = null;
    }
    if (mounted) {
      setState(() {
        _directory = directory.path;
        _backups = backups;
        _package = package;
      });
    }
  }

  /// Runs [action] with the other actions disabled, and shows the message it answers with, or its error.
  Future<void> _run(Future<String?> Function(AppLocalizations) action, String Function(String) describeError) async {
    if (_busy) {
      return;
    }
    final localizations = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    String? status;
    try {
      status = await action(localizations);
    } on FormatException catch (e) {
      status = describeError(e.message);
    } on StateError catch (e) {
      status = describeError(e.message);
    } on FileSystemException catch (e) {
      status = describeError(e.message);
    } on PlatformException catch (e) {
      status = describeError(e.message ?? e.code);
    } catch (e) {
      status = describeError("$e");
    }
    await _load();
    if (mounted) {
      setState(() {
        _busy = false;
        if (status != null) {
          _status = status;
        }
      });
    }
  }

  Future<void> _export() => _run(
        (localizations) async => localizations.backupSavedTo((await _service.export()).path),
        AppLocalizations.of(context)!.backupExportFailed,
      );

  Future<void> _saveCopy() => _run(
        (localizations) async {
          try {
            final saved = await _channel.saveBackupFile(
              BackupService.fileName(DateTime.now()),
              await _service.encodeBackup(),
            );
            return saved ? localizations.backupCopySaved : null;
          } on PlatformException catch (e) {
            if (e.code == "unavailable") {
              return localizations.backupSaveUnavailable;
            }
            rethrow;
          }
        },
        AppLocalizations.of(context)!.backupExportFailed,
      );

  Future<void> _restoreFromPicker() => _run(
        (localizations) async {
          final String? text;
          try {
            text = await _channel.openBackupFile();
          } on PlatformException catch (e) {
            if (e.code == "unavailable") {
              return localizations.backupOpenUnavailable;
            }
            rethrow;
          }
          if (text == null || !await _confirmRestore(localizations)) {
            return null;
          }
          return _describe(localizations, await _service.restoreText(text));
        },
        AppLocalizations.of(context)!.backupRestoreFailed,
      );

  Future<void> _restoreFile(File file) => _run(
        (localizations) async {
          if (!await _confirmRestore(localizations)) {
            return null;
          }
          return _describe(localizations, await _service.restoreFile(file));
        },
        AppLocalizations.of(context)!.backupRestoreFailed,
      );

  Future<bool> _confirmRestore(AppLocalizations localizations) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(localizations.backupRestoreTitle),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(localizations.backupRestoreBody(kBeforeRestoreFileName)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
            ),
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(localizations.backupRestore),
            ),
          ],
        ),
      ) ??
      false;

  static String _describe(AppLocalizations localizations, RestoreSummary summary) => summary.skippedApps > 0
      ? localizations.backupRestoredSkipped(summary.skippedApps)
      : localizations.backupRestored;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final hintStyle = textTheme.bodySmall?.copyWith(color: Colors.white54);
    final dateFormat = DateFormat.yMMMd().add_Hm();

    return Column(
      children: [
        SettingsPageHeader(title: localizations.backupSettings),
        Expanded(
          child: ListView(
            children: [
              FocusableSettingsTile(
                autofocus: true,
                leading: const Icon(Icons.save_alt),
                title: Text(localizations.backupExport, style: textTheme.bodyMedium),
                subtitle: Text(localizations.backupExportHint, style: textTheme.bodySmall),
                onPressed: _busy ? null : _export,
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.drive_file_move_outline),
                title: Text(localizations.backupSaveCopy, style: textTheme.bodyMedium),
                subtitle: Text(localizations.backupSaveCopyHint, style: textTheme.bodySmall),
                onPressed: _busy ? null : _saveCopy,
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: Text(localizations.backupRestoreFromFile, style: textTheme.bodyMedium),
                onPressed: _busy ? null : _restoreFromPicker,
              ),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
                  child: Text(_status!, style: textTheme.bodySmall),
                ),
              const SettingsSectionDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
                child: Text(localizations.backupSavedBackups, style: textTheme.titleSmall),
              ),
              if (_backups.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                  child: Text(localizations.backupNoBackups, style: hintStyle),
                ),
              for (final (file, modified) in _backups)
                FocusableSettingsTile(
                  key: ValueKey(file.path),
                  leading: const Icon(Icons.description_outlined),
                  title: Text(p.basename(file.path), style: textTheme.bodyMedium),
                  subtitle: Text(
                    p.basename(file.path) == kBeforeRestoreFileName
                        ? "${localizations.backupBeforeRestore} · ${dateFormat.format(modified)}"
                        : dateFormat.format(modified),
                    style: textTheme.bodySmall,
                  ),
                  onPressed: _busy ? null : () => _restoreFile(file),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                child: Text(
                  [
                    if (_directory != null) localizations.backupFolderHint(_directory!),
                    if (_package != null) localizations.backupAdbHint(_package!),
                  ].join("\n\n"),
                  style: hintStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
