//
//  NativeSearch.swift
//  Runner
//
//  Created by Aaron Madlon-Kay on 2021/06/03.
//

import Foundation
import Flutter

func handleNativeSearchMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "findFileForId":
        DispatchQueue.global(qos: .userInitiated).async {
            findFileForId(call, result)
        }
    default:
        result(FlutterError(code: "UnsupportedMethod", message: "\(call.method) is not supported", details: nil))
    }
}

private func findFileForId(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String:Any?] else {
        result(FlutterError(code: "MissingArgs", message: "Required arguments missing", details: "\(call.method) requires 'id', 'dirIdentifier'"))
        return
    }
    guard let id = args["id"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'id'"))
        return
    }
    guard let dirIdentifier = args["dirIdentifier"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'dirIdentifier'"))
        return
    }

    guard let url = restoreUrl(from: dirIdentifier) else {
        result(FlutterError(code: "InvalidDataError", message: "Unable to restore URL from identifier.", details: nil))
        return
    }

    // https://developer.apple.com/documentation/uikit/view_controllers/providing_access_to_directories

    guard url.startAccessingSecurityScopedResource() else {
        log("Failed to access security scoped resource: \(url)")
        return
    }

    defer { url.stopAccessingSecurityScopedResource() }

    var error: NSError? = nil
    var success = false
    NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { url in
        let keys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])

        guard let fileList =
                FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys)) else {
            log("Failed to obtain enumerator")
            return
        }

        for case let file as URL in fileList {
            log("Looking at file \(file)")
            guard let values = try? file.resourceValues(forKeys: keys),
                  let isDirectory = values.isDirectory,
                  let name = values.name else {
                log("Failed to access resource values: \(file)")
                continue
            }
            guard !isDirectory else {
                continue
            }
            guard name.hasSuffix(".org") || name.hasSuffix(".org.icloud") else {
                continue
            }

            let accessing = file.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    file.stopAccessingSecurityScopedResource()
                }
            }
            if !accessing {
                // TODO: This seems to be the normal case. Remove log? Don't bother accessing?
                //log("Failed to access security scoped resource: \(file)")
            }

            var fileError: NSError? = nil
            NSFileCoordinator().coordinate(readingItemAt: file, error: &fileError) { fileUrl in
                log("Searching \(fileUrl) for ID \(id)")
                if fileContainsId(fileUrl: fileUrl, id: id) {
                    guard let bookmark = try? fileUrl.bookmarkData() else {
                        log("Failed to get bookmark for file: \(fileUrl)")
                        return
                    }
                    DispatchQueue.main.async {
                        // Result compatible with file_picker_writable
                        result([
                            "path": fileUrl.path,
                            "identifier": bookmark.base64EncodedString(),
                            "persistable": "true",
                            "uri": fileUrl.absoluteString,
                            "fileName": fileUrl.lastPathComponent,
                        ])
                    }
                    success = true
                }
            }
            if let fileError = fileError {
                log("Error accessing file: \(fileError)")
            }
            if success {
                break
            }
        }
    }
    if let error = error {
        log("Error accessing dir: \(error)")
    }
    if (!success) {
        result(nil)
    }
}

private let idPattern = try! NSRegularExpression(pattern: #"^\s*:ID:\s*(?<value>\S+)\s*$"#, options: [.caseInsensitive])

private func fileContainsId(fileUrl: URL, id: String) -> Bool {
    guard let reader = LineReader(url: fileUrl) else {
        log("Failed to instantiate line reader")
        return false
    }
    for line in reader {
        let found = autoreleasepool { () -> Bool in
            guard line.contains(id) else {
                return false
            }
            return findIdInString(line) == id
        }
        if found {
            return true
        }
    }
    return false
}

private func findIdInString(_ str: String) -> String? {
    let range = NSRange(str.startIndex..<str.endIndex, in: str)
    guard let result = idPattern.firstMatch(in: str, range: range) else {
        return nil
    }
    let matchRange = result.range(at: 1)
    guard let valueRange = Range(matchRange, in: str) else {
        return nil
    }
    return String(str[valueRange])
}

private func restoreUrl(from identifier: String) -> URL? {
    guard let bookmark = Data(base64Encoded: identifier) else {
        return nil
    }
    var isStale: Bool = false
    guard let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else {
        return nil
    }
    log("url: \(url) / isStale: \(isStale)");
    return url
}

func log(_ message: String) {
    //#if DEBUG
        print(message)
    //#endif
}
