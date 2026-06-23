import 'package:flutter/services.dart';

import 'flutter_screenshot_detect_platform_interface.dart';
import 'src/flutter_screenshot_event.dart';

class MethodChannelFlutterScreenshotDetect
    extends FlutterScreenshotDetectPlatform {
  static const EventChannel _eventChannel =
      EventChannel('com.ss.detect/events');

  @override
  Stream<FlutterScreenshotEvent> get onScreenshot {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return FlutterScreenshotEvent.fromMap(event as Map<Object?, Object?>);
    });
  }
}
