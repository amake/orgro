import UIKit
import Flutter
import flutter_local_notifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        let nsChannel = FlutterMethodChannel(name: "com.madlonkay.orgro/native_search", binaryMessenger: engineBridge.applicationRegistrar.messenger())
        nsChannel.setMethodCallHandler(handleNativeSearchMethod)

        let apChannel = FlutterMethodChannel(name: "com.madlonkay.orgro/app_purchase", binaryMessenger: engineBridge.applicationRegistrar.messenger())
        apChannel.setMethodCallHandler(handleAppPurchaseMethod)

        UNUserNotificationCenter.current().delegate = self

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
