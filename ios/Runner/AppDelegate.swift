import UIKit
import Flutter
import flutter_local_notifications
import workmanager_apple

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
        let nsRegistrar = registry.registrar(forPlugin: "native_search")!
        let nsChannel = FlutterMethodChannel(name: "com.madlonkay.orgro/native_search", binaryMessenger: nsRegistrar.messenger())
        nsChannel.setMethodCallHandler(handleNativeSearchMethod)

        let apRegistrar = registry.registrar(forPlugin: "app_purchase")!
        let apChannel = FlutterMethodChannel(name: "com.madlonkay.orgro/app_purchase", binaryMessenger: apRegistrar.messenger())
        apChannel.setMethodCallHandler(handleAppPurchaseMethod)

        GeneratedPluginRegistrant.register(with: registry)

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }

        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        #if DEBUG
        WorkmanagerDebug.setCurrent(LoggingDebugHandler())
        #endif

        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }
    }
}
