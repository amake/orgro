//
//  AppPurchase.swift
//  Runner
//
//  Created by Aaron Madlon-Kay on 2025/12/20.
//

// TODO(aaron): This entire file might not be necessary. Check if the app
// purchase shows up in the purchase stream; if yes, we can remove this.

import Foundation
import Flutter
import StoreKit

private var jobs = ConcurrentSet<String>()

func handleAppPurchaseMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAppPurchaseInfo":
        Task {
            if #available(iOS 16.0, *) {
                await getAppPurchaseInfo(call, result)
            } else {
                // TODO(aaron): Fallback on earlier versions
            }
        }
    default:
        result(FlutterError(code: "UnsupportedMethod", message: "\(call.method) is not supported", details: nil))
    }
}

@available(iOS 16.0, *)
private func getAppPurchaseInfo(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) async {
    guard let args = call.arguments as? [String:Any?] else {
        result(FlutterError(code: "MissingArgs", message: "Required arguments missing", details: "\(call.method) requires 'refresh'"))
        return
    }
    guard let refresh = args["refresh"] as? Bool else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'refresh'"))
        return
    }
    do {
        let verificationResult = refresh ? try await AppTransaction.refresh() : try await AppTransaction.shared
        switch verificationResult {
        case .verified(let appTransaction):
            result([
                "originalAppVersion": appTransaction.originalAppVersion,
                "originalPurchaseDate": appTransaction.originalPurchaseDate.timeIntervalSince1970
            ])
        case .unverified(_, let verificationError):
            print("AMK error \(verificationError)")
            result(FlutterError(code: "VerificationError", message: "The app transaction could not be verified", details: verificationError.localizedDescription))
        }
    }
    catch {
        print("AMK error \(error)")
        result(FlutterError(code: "UnknownError", message: error.localizedDescription, details: nil))
    }
}
