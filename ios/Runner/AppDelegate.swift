import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    private var openFileChannel : FlutterMethodChannel!

    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        if let viewController = window.rootViewController as? FlutterViewController {
            openFileChannel = FlutterMethodChannel(name: "org.madlonkay.orgro/openFile", binaryMessenger: viewController.binaryMessenger)
            openFileChannel.setMethodCallHandler(handleMethod(call:result:))
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func handleMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method) {
        case "ready":
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        loadCopiedFile(url)
        return true
    }

    private func loadCopiedFile(_ url: URL) {
        openFileChannel.invokeMethod("loadUrl", arguments: url.absoluteString) { result in
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                // TODO: Error handling
                print(error)
            }
        }
    }
}
