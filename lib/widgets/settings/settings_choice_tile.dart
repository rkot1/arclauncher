import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A settings row cycling through [values] in place: OK and right pick the
/// next value, left the previous one. Suited to D-pad remotes, where a
/// sub-page per option would be slow to navigate.
class SettingsChoiceTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<T> values;
  final T value;
  final String Function(T value) labelOf;

  /// Optional sample drawn next to the value label (a colour chip, a font sample...).
  final Widget Function(T value)? swatchOf;
  final ValueChanged<T> onChanged;
  final bool autofocus;

  const SettingsChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.values,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    this.swatchOf,
    this.autofocus = false,
  });

  void _step(int delta) {
    if (values.isEmpty) {
      return;
    }
    final index = values.indexOf(value);
    onChanged(values[((index < 0 ? 0 : index) + delta) % values.length]);
  }

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white);
    final arrowColor = Colors.white.withValues(alpha: 0.35);

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _step(-1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _step(1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: FocusableSettingsTile(
        autofocus: autofocus,
        leading: Icon(icon),
        title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left_rounded, size: 18, color: arrowColor),
            if (swatchOf != null) ...[swatchOf!(value), const SizedBox(width: 6)],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(labelOf(value), style: valueStyle, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: arrowColor),
          ],
        ),
        onPressed: () => _step(1),
      ),
    );
  }
}

/// A small rounded colour sample for [SettingsChoiceTile.swatchOf].
class SettingsColorSwatch extends StatelessWidget {
  final Color? color;
  final Gradient? gradient;

  const SettingsColorSwatch({super.key, this.color, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }
}
