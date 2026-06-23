# flutter_screenshot_detect_plus

本地截图检测插件，用于监听 Android 和 iOS 的系统截图事件。

## 行为

- Android 14 及以上：使用 `Activity.ScreenCaptureCallback`。
- Android 14 以下：监听 `MediaStore.Images` 变化，并且只在文件名或路径明确包含截图关键词时触发。
- iOS：监听 `UIApplication.userDidTakeScreenshotNotification`。
- 所有事件通过 Dart `Stream<FlutterScreenshotEvent>` 输出。

## Android 旧版限制

Android 14 以下没有专用截图回调，只能通过媒体库变化间接判断。当前实现为了避免误报，不会在媒体库查询失败、无权限或空结果时默认当作截图。

这意味着旧版 Android 在没有相册读取能力或系统屏蔽媒体字段时，可能漏报截图，但不会把普通图片新增误报成截图。

## 使用

```dart
import 'dart:async';

import 'package:flutter_screenshot_detect_plus/flutter_screenshot_detect.dart';

final detector = FlutterScreenshotDetect();
StreamSubscription<FlutterScreenshotEvent>? subscription;

void start() {
  subscription ??= detector.startListening((event) {
    // event.method: screen_capture_callback / content_observer / user_did_take_screenshot
    // event.timestamp: 检测时间
    // event.path: Android 14 以下可能返回的媒体 URI
  });
}

Future<void> stop() async {
  await subscription?.cancel();
  subscription = null;
  detector.dispose();
}
```

也可以直接监听：

```dart
final subscription = detector.onScreenshot.listen((event) {
  // handle event
});
```

## 事件字段

- `method`：原生侧检测方式。
- `timestamp`：截图检测时间，原生侧统一以微秒时间戳传递。
- `path`：截图媒体 URI，仅 Android 14 以下的媒体库监听可能返回。

## 校验

```bash
flutter analyze
flutter test
```
