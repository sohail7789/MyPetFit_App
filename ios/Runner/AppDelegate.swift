import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required by flutter_local_notifications for the assessment-retake
    // reminder (lib/services/reminder_gateway.dart). Without a delegate, a
    // scheduled notification that arrives while the app is in the
    // foreground is dropped instead of shown, and taps on a delivered one
    // are not routed back into the plugin.
    //
    // The conditional cast is the form the plugin documents: it compiles
    // whether or not this Flutter version's FlutterAppDelegate declares
    // conformance, rather than failing the build if it ever stops doing so.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate =
        self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
