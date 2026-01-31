//
//  AppPurchase.swift
//  Runner
//
//  Created by Aaron Madlon-Kay on 2025/12/20.
//

import Foundation
import Flutter
import StoreKit
import os

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: "AppPurchase"
)

func handleAppPurchaseMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAppPurchaseInfo":
        Task {
            await getAppPurchaseInfo(call, result)
        }
    default:
        result(FlutterError(code: "UnsupportedMethod", message: "\(call.method) is not supported", details: nil))
    }
}

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
                "originalPurchaseTimestamp": appTransaction.originalPurchaseDate.timeIntervalSince1970,
                "environment": appTransaction.environment.rawValue,
            ])
        case .unverified(_, let verificationError):
            logger.critical("AppTransaction verification error: \(verificationError)")
            result(FlutterError(code: "VerificationError", message: "The app transaction could not be verified", details: verificationError.localizedDescription))
        }
    }
    catch {
        logger.critical("Error checking AppTransaction: \(error)")
        result(FlutterError(code: "UnknownError", message: error.localizedDescription, details: nil))
    }
}
