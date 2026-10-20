import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static var channel: FlutterMethodChannel?
  private static var pendingUrl: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = launchOptions?[.url] as? URL {
      AppDelegate.receive(url)
    }
    // Automation/shortcut entry used by screenshots and device tests:
    // SIMCTL_CHILD_DOUBAO_DEEPLINK=doubaoinput://keyboard
    if let deep = ProcessInfo.processInfo.environment["DOUBAO_DEEPLINK"], !deep.isEmpty {
      AppDelegate.pendingUrl = deep
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: "com.huapohen.doubaoinput.flutter/deeplink",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getInitialUrl" {
        result(AppDelegate.pendingUrl)
        AppDelegate.pendingUrl = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    AppDelegate.channel = channel
  }

  static func receive(_ url: URL) {
    let value = url.absoluteString
    if let channel = channel {
      channel.invokeMethod("open", arguments: value)
    } else {
      pendingUrl = value
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    AppDelegate.receive(url)
    return true
  }
}
