import 'dart:math';

/// A size and density to draw the whole display at, named the way the `resolution` adb command takes it.
class Resolution {
  /// "native", "1440p", "1080p", or "custom" for a size set some other way, such as `adb shell wm size`.
  final String name;
  final int width;
  final int height;
  final int density;

  const Resolution(this.name, this.width, this.height, this.density);

  bool get isNative => name == "native";

  bool sameAs(Resolution other) => width == other.width && height == other.height && density == other.density;

  @override
  String toString() => "$name (${width}x$height, density $density)";
}

/// What the display is drawn at, what its panel has, and the resolutions the launcher offers.
class DisplayResolution {
  /// Lines on the short side of the standard resolutions offered below the panel's own.
  static const Map<String, int> standardLines = {"1440p": 1440, "1080p": 1080};

  final Resolution native;
  final Resolution current;

  /// Whether this build can reach the window manager calls at all; the Google Play build cannot.
  final bool available;

  /// Whether the launcher holds WRITE_SECURE_SETTINGS, which only adb can grant.
  final bool canChange;

  /// The panel's own resolution, then each standard one below it, in the panel's shape and with the density
  /// scaled along, so text and icons keep their size on screen.
  final List<Resolution> options;

  DisplayResolution._(this.native, this.current, this.available, this.canChange, this.options);

  factory DisplayResolution({
    required int physicalWidth,
    required int physicalHeight,
    required int physicalDensity,
    required int width,
    required int height,
    required int density,
    required bool available,
    required bool canChange,
  }) {
    final native = Resolution("native", physicalWidth, physicalHeight, physicalDensity);
    final shortSide = min(physicalWidth, physicalHeight);
    final options = [
      native,
      for (final MapEntry(key: name, value: lines) in standardLines.entries)
        if (lines < shortSide)
          Resolution(
            name,
            (physicalWidth * lines / shortSide).round(),
            (physicalHeight * lines / shortSide).round(),
            (physicalDensity * lines / shortSide).round(),
          ),
    ];
    final drawn = Resolution("custom", width, height, density);
    final current = options.firstWhere((option) => option.sameAs(drawn), orElse: () => drawn);
    return DisplayResolution._(native, current, available, canChange, options);
  }

  /// From what the platform channel's getDisplayResolution answers.
  factory DisplayResolution.fromMap(Map<dynamic, dynamic> map) => DisplayResolution(
        physicalWidth: map["physicalWidth"] as int,
        physicalHeight: map["physicalHeight"] as int,
        physicalDensity: map["physicalDensity"] as int,
        width: map["width"] as int,
        height: map["height"] as int,
        density: map["density"] as int,
        available: map["available"] as bool,
        canChange: map["canChange"] as bool,
      );

  /// The option called [name], or null.
  Resolution? option(String name) {
    for (final option in options) {
      if (option.name == name) {
        return option;
      }
    }
    return null;
  }
}
