import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/display_resolution.dart';

/// Reads and changes the resolution the whole display is drawn at, as `adb shell wm size` and `wm density` do.
class DisplayResolutionService {
  final FLauncherChannel _channel;

  DisplayResolutionService(this._channel);

  /// The adb command that lets the launcher change the resolution; Android offers no way to ask for it on screen.
  static String grantCommand(String package) => "adb shell pm grant $package android.permission.WRITE_SECURE_SETTINGS";

  Future<DisplayResolution> read() async => DisplayResolution.fromMap(await _channel.getDisplayResolution());

  /// Draws the display at [resolution]. Throws a [PlatformException] coded "permission" when the launcher may not,
  /// and "unavailable" when this Android version hides the calls from apps.
  Future<void> apply(Resolution resolution) =>
      _channel.setDisplayResolution(resolution.width, resolution.height, resolution.density);
}
