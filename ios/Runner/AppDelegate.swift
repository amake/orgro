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
        switch options[.openInPlace] as? Bool {
        case .some(true):
            loadInPlace(url)
        default:
            loadCopiedFile(url)
        }
        return true
    }

    private func loadInPlace(_ url: URL) {
        DispatchQueue.global().async {
            // Adapted from https://github.com/palmin/open-in-place/blob/97d3e0cd9bb6f4e0a84e167b31d5dbf729c7aa8a/OpenInPlace/UrlCoordination.swift
            let error: NSErrorPointer = nil
            NSFileCoordinator(filePresenter: nil).coordinate(readingItemAt: url, options: [], error: error) { url in
                if url.startAccessingSecurityScopedResource() {
                    self.openFileChannel.invokeMethod("loadUrl", arguments: url.absoluteString) { result in
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            }
            // TODO: Error handling
            if let error = error?.pointee {
                print(error)
            }
        }
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
