//
//  Clipboard.swift
//  Runner
//
//  Created by Aaron Madlon-Kay on 2026/4/14.
//

import Foundation
import UniformTypeIdentifiers
import Flutter
import os

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: "Clipboard"
)

func handleClipboardMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
        switch call.method {
        case "hasClipboardImageData":
            hasClipboardImageData(call, result)
        case "saveClipboardImages":
            try saveClipboardImages(call, result)
        default:
            // saveKeyboardImage handles an Android-only feature (keyboard image insertion)
            result(FlutterError(code: "UnsupportedMethod", message: "\(call.method) is not supported", details: nil))
        }
    } catch {
        result(FlutterError(code: "ClipboardError", message: error.localizedDescription, details: nil))
    }
}
private func hasClipboardImageData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result(UIPasteboard.general.hasImages)
}

private func saveClipboardImages(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
    guard let args = call.arguments as? [String:Any?] else {
        result(FlutterError(code: "MissingArgs", message: "Required arguments missing", details: "\(call.method) requires 'requestId'"))
        return
    }
    guard let dirIdentifier = args["dirIdentifier"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'dirIdentifier'"))
        return
    }
    guard let relativePath = args["relativePath"] as? String? else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'relativePath'"))
        return
    }
    guard let filenamePrefix = args["filenamePrefix"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'filenamePrefix'"))
        return
    }

    guard let bookmark = Data(base64Encoded: dirIdentifier) else {
        result(FlutterError(code: "Invalid identifier", message: "Unable to decode bookmark/identifier.", details: nil))
        return
    }

    var isStale: Bool = false
    var url = try URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale)
    if relativePath != nil {
        url = url.appending(path: relativePath!, directoryHint: .isDirectory)
    }

    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

    logger.debug("url: \(url) / isStale: \(isStale)");

    let providers = UIPasteboard.general.itemProviders

    Task {
        var results: [String] = []

        for (i, provider) in providers.enumerated() {
            await handleProvider(provider) { data, type in
                let ext = type.preferredFilenameExtension ?? "dat"
                let fileName = "\(filenamePrefix)_\(i).\(ext)"
                let imageFile = url.appendingPathComponent(fileName)
                try data.write(to: imageFile)
                results.append(fileName)
            }
        }

        result(results)
    }
}

private func handleProvider(_ provider: NSItemProvider, _ process: (_ data: Data, _ type: UTType) async throws -> Void) async {
    let types = provider.registeredTypeIdentifiers
        .compactMap { UTType($0) }
        .filter { $0.conforms(to: .image) }

    guard !types.isEmpty else {
        logger.debug("Provider \(provider) had no relevant types")
        return
    }

    let sortedTypes = types.sorted { score(for: $0) > score(for: $1) }

    // Try each type in order
    for type in sortedTypes {
        do {
            logger.debug("Getting data from \(provider) for type \(type)")
            let data = try await provider.data(for: type)
            try await process(data, type)
            return
        } catch {
            logger.error("Failed to save data from provider \(provider) with type \(type): \(error)")
            continue
        }
    }

    // Final fallback: UIImage
    if provider.canLoadObject(ofClass: UIImage.self) {
        do {
            logger.debug("Getting data from \(provider) via fallback method")
            let image = try await provider.uiImage()
            if let data = image.pngData() {
                try await process(data, .png)
            }
        } catch {
            // give up
            logger.error("Exhaused all attempts to save image from provider \(provider)")
        }
    }
}

private func score(for type: UTType) -> Int {
    if type == .image { return 0 }

    var score = 1

    if type.preferredFilenameExtension != nil {
        score += 2
    }

    if type == .png || type == .tiff {
        score += 2
    }

    if type == .heic || type == .heif {
        score += 2
    }

    if type == .jpeg {
        score += 1
    }

    return score
}

private extension NSItemProvider {
    func data(for type: UTType) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let _ = self.loadDataRepresentation(for: type) { data, error in
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "NSItemProviderError", code: -1))
                }
            }
        }
    }

    func uiImage() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            self.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "NSItemProviderError", code: -2))
                }
            }
        }
    }
}
