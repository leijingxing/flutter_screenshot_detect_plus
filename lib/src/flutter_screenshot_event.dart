/// 系统截图检测事件。
class FlutterScreenshotEvent {
  /// 原生侧用于检测截图的方式。
  final String method;

  /// 原生侧检测到截图的时间。
  final DateTime timestamp;

  /// 截图对应的媒体 URI，仅 Android 14 以下的媒体库监听可能返回。
  final String? path;

  const FlutterScreenshotEvent({
    required this.method,
    required this.timestamp,
    this.path,
  });

  factory FlutterScreenshotEvent.fromMap(Map<Object?, Object?> map) {
    final timestamp = map['timestamp'];
    final path = map['path'];
    return FlutterScreenshotEvent(
      method: map['method'] as String? ?? 'unknown',
      timestamp: DateTime.fromMicrosecondsSinceEpoch(
        timestamp is int ? timestamp : (timestamp as num).toInt(),
      ),
      path: path is String && path.isNotEmpty ? path : null,
    );
  }

  @override
  String toString() {
    return 'FlutterScreenshotEvent(method: $method, timestamp: $timestamp, path: $path)';
  }
}
