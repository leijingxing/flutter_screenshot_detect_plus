// screenshot_detector/lib/screenshot_detector_platform_interface.dart
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_screenshot_detect_method_channel.dart';
import 'src/flutter_screenshot_event.dart';

abstract class FlutterScreenshotDetectPlatform extends PlatformInterface {
  FlutterScreenshotDetectPlatform() : super(token: _token);

  static final Object _token = Object();
  static FlutterScreenshotDetectPlatform _instance =
      MethodChannelFlutterScreenshotDetect();

  static FlutterScreenshotDetectPlatform get instance => _instance;

  static set instance(FlutterScreenshotDetectPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Stream<FlutterScreenshotEvent> get onScreenshot {
    throw UnimplementedError('onScreenshot has not been implemented.');
  }
}
