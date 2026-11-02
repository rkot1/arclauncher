import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/display_resolution.dart';
import 'package:flauncher/providers/display_resolution_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// Picks the resolution the whole display is drawn at. A new one is kept only once confirmed, so a picture that
/// went wrong comes back by itself.
class DisplayResolutionPage extends StatefulWidget {
  static const String routeName = "display_resolution_panel";

  /// How long a new resolution waits to be confirmed before going back.
  static const Duration keepTimeout = Duration(seconds: 15);

  const DisplayResolutionPage({super.key});

  @override
  State<DisplayResolutionPage> createState() => _DisplayResolutionPageState();
}

class _DisplayResolutionPageState extends State<DisplayResolutionPage> with WidgetsBindingObserver {
  late final DisplayResolutionService _service = Provider.of(context, listen: false);

  DisplayResolution? _display;
  String? _package;
  String? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _loadPackage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The display reports a new size and density only once the system has switched to them.
  @override
  void didChangeMetrics() => _load();

  Future<void> _load() async {
    final display = await _service.read();
    if (mounted) {
      setState(() => _display = display);
    }
  }

  /// For the grant command shown while the permission is missing.
  Future<void> _loadPackage() async {
    try {
      final package = (await PackageInfo.fromPlatform()).packageName;
      if (mounted) {
        setState(() => _package = package);
      }
    } catch (_) {}
  }

  Future<void> _choose(Resolution resolution) async {
    final display = _display;
    if (display == null || _busy || resolution.sameAs(display.current)) {
      return;
    }
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _status = null;
    });
    String? status;
    try {
      await _service.apply(resolution);
      final keep = mounted && await _confirmKeep();
      if (!keep) {
        await _service.apply(display.current);
      }
    } on PlatformException catch (e) {
      status = e.code == "unavailable"
          ? localizations.displayResolutionUnavailable
          : localizations.displayResolutionFailed(e.message ?? e.code);
    }
    await _load();
    if (mounted) {
      setState(() {
        _busy = false;
        _status = status;
      });
    }
  }

  Future<bool> _confirmKeep() async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _KeepResolutionDialog(),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final hintStyle = textTheme.bodySmall?.copyWith(color: Colors.white54);
    final display = _display;

    return Column(
      children: [
        SettingsPageHeader(title: localizations.displayResolution),
        Expanded(
          child: ListView(
            children: [
              if (display != null) ...[
                if (!display.options.contains(display.current)) _tile(display.current, selected: true),
                for (final option in display.options)
                  _tile(
                    option,
                    selected: option == display.current,
                    onPressed: display.available && display.canChange && !_busy ? () => _choose(option) : null,
                  ),
              ],
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
                  child: Text(_status!, style: textTheme.bodySmall),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                child: Text(
                  [
                    localizations.displayResolutionHint,
                    if (display != null && !display.available) localizations.displayResolutionUnavailable,
                    if (display != null && display.available && !display.canChange && _package != null)
                      localizations.displayResolutionPermissionHint(DisplayResolutionService.grantCommand(_package!)),
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

  Widget _tile(Resolution resolution, {required bool selected, VoidCallback? onPressed}) {
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final name = switch (resolution.name) {
      "native" => localizations.displayResolutionNative,
      "custom" => localizations.displayResolutionCustom,
      _ => resolution.name,
    };
    return FocusableSettingsTile(
      key: ValueKey(resolution.name),
      autofocus: selected,
      frameLeading: false,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Theme.of(context).colorScheme.secondary : Colors.grey,
      ),
      title: Text(name, style: textTheme.bodyMedium),
      subtitle: Text(
        localizations.displayResolutionDetails(resolution.width, resolution.height, resolution.density),
        style: textTheme.bodySmall,
      ),
      onPressed: onPressed,
    );
  }
}

/// Asks whether to keep the new resolution, counting down, and answers false by itself when time is up.
class _KeepResolutionDialog extends StatefulWidget {
  const _KeepResolutionDialog();

  @override
  State<_KeepResolutionDialog> createState() => _KeepResolutionDialogState();
}

class _KeepResolutionDialogState extends State<_KeepResolutionDialog> {
  late final Timer _timer;
  int _secondsLeft = DisplayResolutionPage.keepTimeout.inSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _timer.cancel();
        Navigator.of(context).pop(false);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(localizations.displayResolutionKeepTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Text(localizations.displayResolutionKeepBody(_secondsLeft)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(localizations.displayResolutionRevert),
        ),
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(localizations.displayResolutionKeep),
        ),
      ],
    );
  }
}
