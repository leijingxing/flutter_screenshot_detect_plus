// lib/screenshot_detector.dart
import 'dart:async';

import 'flutter_screenshot_detect_platform_interface.dart';
import 'src/flutter_screenshot_event.dart';

export 'src/flutter_screenshot_event.dart';

class FlutterScreenshotDetect {
  Stream<FlutterScreenshotEvent>? _screenshotStream;

  /// Represents a screenshot detection event.
  Stream<FlutterScreenshotEvent> get onScreenshot {
    _screenshotStream ??= FlutterScreenshotDetectPlatform.instance.onScreenshot;
    return _screenshotStream!;
  }

  /// Starts listening for screenshot events.
  StreamSubscription<FlutterScreenshotEvent> startListening(
    void Function(FlutterScreenshotEvent event) onScreenshotTaken,
  ) {
    return onScreenshot.listen(onScreenshotTaken);
  }

  /// Clears the cached stream reference.
  void dispose() {
    _screenshotStream = null;
  }
}
