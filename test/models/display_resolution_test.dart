import 'package:flauncher/models/display_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DisplayResolution panel({
    int physicalWidth = 3840,
    int physicalHeight = 2160,
    int physicalDensity = 480,
    int? width,
    int? height,
    int? density,
  }) =>
      DisplayResolution(
        physicalWidth: physicalWidth,
        physicalHeight: physicalHeight,
        physicalDensity: physicalDensity,
        width: width ?? physicalWidth,
        height: height ?? physicalHeight,
        density: density ?? physicalDensity,
        available: true,
        canChange: true,
      );

  test("a 4K panel offers 1440p and 1080p with the density scaled along", () {
    final display = panel();

    expect([for (final option in display.options) "$option"], [
      "native (3840x2160, density 480)",
      "1440p (2560x1440, density 320)",
      "1080p (1920x1080, density 240)",
    ]);
    expect(display.current, same(display.native));
  });

  test("a 1080p panel offers only its own resolution", () {
    final display = panel(physicalWidth: 1920, physicalHeight: 1080, physicalDensity: 320);

    expect([for (final option in display.options) option.name], ["native"]);
  });

  test("the current resolution is the option it matches, or custom", () {
    expect(panel(width: 2560, height: 1440, density: 320).current.name, "1440p");

    // `adb shell wm size 2560x1440` without `wm density` leaves the density at the panel's.
    final custom = panel(width: 2560, height: 1440).current;
    expect(custom.name, "custom");
    expect("$custom", "custom (2560x1440, density 480)");
  });

  test("option finds a resolution by name", () {
    final display = panel();

    expect(display.option("1080p")?.width, 1920);
    expect(display.option("720p"), isNull);
  });
}
