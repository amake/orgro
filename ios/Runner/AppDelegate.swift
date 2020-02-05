import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    private var openFileChannel : FlutterMethodChannel?

    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        if let viewController = window.rootViewController as? FlutterViewController {
            openFileChannel = FlutterMethodChannel(name: "org.madlonkay.orgro/openFile", binaryMessenger: viewController.binaryMessenger)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let openFileChannel = openFileChannel else {
            return false
        }
        if let content = try? String(contentsOf: url) {
            openFileChannel.invokeMethod("loadString", arguments: content)
            return true
        } else {
            return false
        }
    }
}
