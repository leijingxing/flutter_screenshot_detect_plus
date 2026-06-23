import 'dart:async';

import 'package:flutter_screenshot_detect_plus/flutter_screenshot_detect.dart';
import 'package:flutter_screenshot_detect_plus/flutter_screenshot_detect_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeScreenshotDetectPlatform extends FlutterScreenshotDetectPlatform
    with MockPlatformInterfaceMixin {
  FakeScreenshotDetectPlatform(this.controller);

  final StreamController<FlutterScreenshotEvent> controller;

  @override
  Stream<FlutterScreenshotEvent> get onScreenshot => controller.stream;
}

void main() {
  test('parses screenshot event payload', () {
    final event = FlutterScreenshotEvent.fromMap(<Object?, Object?>{
      'method': 'content_observer',
      'timestamp': 1710000000000000,
      'path': 'content://media/external/images/media/1',
    });

    expect(event.method, 'content_observer');
    expect(
      event.timestamp,
      DateTime.fromMicrosecondsSinceEpoch(1710000000000000),
    );
    expect(event.path, 'content://media/external/images/media/1');
  });

  test('normalizes empty event path to null', () {
    final event = FlutterScreenshotEvent.fromMap(<Object?, Object?>{
      'method': 'user_did_take_screenshot',
      'timestamp': 1710000000000000,
      'path': '',
    });

    expect(event.path, isNull);
  });

  test('startListening returns a cancellable subscription', () async {
    final controller = StreamController<FlutterScreenshotEvent>.broadcast();
    final previousPlatform = FlutterScreenshotDetectPlatform.instance;
    FlutterScreenshotDetectPlatform.instance =
        FakeScreenshotDetectPlatform(controller);
    addTearDown(() async {
      FlutterScreenshotDetectPlatform.instance = previousPlatform;
      await controller.close();
    });

    final detector = FlutterScreenshotDetect();
    final events = <FlutterScreenshotEvent>[];
    final subscription = detector.startListening(events.add);

    controller.add(
      FlutterScreenshotEvent(
        method: 'screen_capture_callback',
        timestamp: DateTime.fromMicrosecondsSinceEpoch(1710000000000000),
      ),
    );
    await pumpEventQueue();

    expect(events, hasLength(1));
    await subscription.cancel();
  });
}
