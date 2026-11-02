import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Height of the strip along the bottom edge that reveals the navigation bar.
const double kNavigationBarRevealZone = 12;

/// Applies [SettingsService.navigationBarMode] to the launcher window and, in
/// [SystemNavigationBarMode.bottomEdge] mode, reveals the navigation bar while
/// the mouse pointer rests on the bottom edge of the screen.
///
/// Once revealed the bar covers the pointer, so the launcher stops receiving
/// hover events there: it is hidden again when the pointer comes back above
/// the bar, on any key press, or when the launcher regains focus.
class SystemNavigationBarController extends StatefulWidget {
  final Widget child;
  final FLauncherChannel? channel;

  const SystemNavigationBarController({super.key, required this.child, this.channel});

  @override
  State<SystemNavigationBarController> createState() => _SystemNavigationBarControllerState();
}

class _SystemNavigationBarControllerState extends State<SystemNavigationBarController> with WidgetsBindingObserver {
  late final FLauncherChannel _channel = widget.channel ?? FLauncherChannel();
  SystemNavigationBarMode? _appliedMode;
  bool _revealed = false;
  double _screenHeight = 0;
  double _bottomInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The platform side hides the bar again whenever the window regains focus.
    if (state == AppLifecycleState.resumed) {
      _revealed = false;
    }
  }

  bool _onKey(KeyEvent event) {
    if (_revealed && event is KeyDownEvent) {
      _setRevealed(false);
    }
    return false;
  }

  void _onHover(PointerHoverEvent event) {
    if (_appliedMode != SystemNavigationBarMode.bottomEdge) {
      return;
    }
    if (!_revealed) {
      if (event.position.dy >= _screenHeight - kNavigationBarRevealZone) {
        _setRevealed(true);
      }
      return;
    }
    // Wait for the pointer to clear the bar (or its usual height while insets update) before hiding it.
    final hideAbove = _screenHeight - (_bottomInset > 0 ? _bottomInset : 48) - 24;
    if (event.position.dy < hideAbove) {
      _setRevealed(false);
    }
  }

  void _setRevealed(bool revealed) {
    _revealed = revealed;
    _channel.setNavigationBarRevealed(revealed);
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.select<SettingsService, SystemNavigationBarMode>((s) => s.navigationBarMode);
    // Leave the window untouched until the bar has been configured once.
    if (mode != _appliedMode && (_appliedMode != null || mode != SystemNavigationBarMode.visible)) {
      _revealed = false;
      _channel.setNavigationBarMode(mode.name);
    }
    _appliedMode = mode;
    _screenHeight = MediaQuery.sizeOf(context).height;
    _bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: _onHover,
      child: widget.child,
    );
  }
}
