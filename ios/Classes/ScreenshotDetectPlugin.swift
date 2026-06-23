// screenshot_detector/ios/Classes/FlutterScreenshotDetectPlugin.swift
import Flutter
import UIKit

public class FlutterScreenshotDetectPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var isObservingScreenshot = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterEventChannel(
            name: "com.ss.detect/events",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterScreenshotDetectPlugin()
        channel.setStreamHandler(instance)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        stopObservingScreenshot()
        self.eventSink = eventSink
        isObservingScreenshot = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onScreenshotCaptured),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopObservingScreenshot()
        eventSink = nil
        return nil
    }

    deinit {
        stopObservingScreenshot()
    }
    
    @objc private func onScreenshotCaptured() {
        let eventData: [String: Any] = [
            "method": "user_did_take_screenshot",
            "timestamp": Int(Date().timeIntervalSince1970 * 1_000_000)
        ]
        
        eventSink?(eventData)
    }

    private func stopObservingScreenshot() {
        guard isObservingScreenshot else { return }
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        isObservingScreenshot = false
    }
}
