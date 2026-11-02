import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/display_resolution.dart';
import 'package:flauncher/providers/display_resolution_service.dart';
import 'package:flutter/services.dart';

/// A 4K panel at 480 dpi whose resolution changes the moment it is applied.
class FakeDisplayResolutionService extends DisplayResolutionService {
  int width;
  int height;
  int density;
  bool available;
  bool canChange;

  /// Thrown by the next [apply], as the platform channel would.
  PlatformException? error;

  final List<Resolution> applied = [];

  FakeDisplayResolutionService({
    this.width = 3840,
    this.height = 2160,
    this.density = 480,
    this.available = true,
    this.canChange = true,
  }) : super(FLauncherChannel());

  @override
  Future<DisplayResolution> read() async => DisplayResolution(
    physicalWidth: 3840,
    physicalHeight: 2160,
    physicalDensity: 480,
    width: width,
    height: height,
    density: density,
    available: available,
    canChange: canChange,
  );

  @override
  Future<void> apply(Resolution resolution) async {
    if (error != null) {
      throw error!;
    }
    applied.add(resolution);
    width = resolution.width;
    height = resolution.height;
    density = resolution.density;
  }
}
