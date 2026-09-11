import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let deviceChannel = FlutterMethodChannel(
        name: "dev.cineus/device",
        binaryMessenger: controller.binaryMessenger
      )
      deviceChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "getTimeZoneIdentifier":
          result(TimeZone.current.identifier)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
