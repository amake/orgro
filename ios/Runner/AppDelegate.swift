import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        pluginRegistrant = self
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func register(with registry: any FlutterPluginRegistry) {
        let registrar = registry.registrar(forPlugin: "native_search")!

        let channel = FlutterMethodChannel(name: "com.madlonkay.orgro/native_search", binaryMessenger: registrar.messenger())

        channel.setMethodCallHandler(handleNativeSearchMethod)

        GeneratedPluginRegistrant.register(with: registry)
    }
}
