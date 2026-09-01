//
//  NativeSearch.swift
//  Runner
//
//  Created by Aaron Madlon-Kay on 2021/06/03.
//

import Foundation
import Flutter
import os

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: "NativeSearch"
)

private var jobs = ConcurrentSet<String>()

private var jobTokenForId = "forId:"
private var jobTokenForNamePrefix = "forNamePrefix:"
private var jobTokenForExactName = "forExactName:"

func handleNativeSearchMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "findFileForId":
        DispatchQueue.global(qos: .userInitiated).async {
            findFileForId(call, result)
        }
    case "findFileWithNamePrefix":
        DispatchQueue.global(qos: .userInitiated).async {
            findFileWithNamePrefix(call, result)
        }
    case "findFileWithExactName":
        DispatchQueue.global(qos: .userInitiated).async {
            findFileWithExactName(call, result)
        }
    case "cancelFindFileForId":
        cancelFindFile(call, result, token: jobTokenForId)
    case "cancelFindFileWithNamePrefix":
        cancelFindFile(call, result, token: jobTokenForNamePrefix)
    case "cancelFindFileWithExactName":
        cancelFindFile(call, result, token: jobTokenForExactName)
    default:
        result(FlutterError(code: "UnsupportedMethod", message: "\(call.method) is not supported", details: nil))
    }
}

private func cancelFindFile(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, token: String) {
    guard let args = call.arguments as? [String:Any?] else {
        result(FlutterError(code: "MissingArgs", message: "Required arguments missing", details: "\(call.method) requires 'requestId'"))
        return
    }
    guard let requestId = args["requestId"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'requestId'"))
        return
    }
    let removed = jobs.remove("\(token)\(requestId)")
    logger.info("Cancelling job \(token)\(requestId); cancelled: \(removed != nil)")
    result(removed != nil)
}

private func findFileForId(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String:Any?] else {
        result(FlutterError(code: "MissingArgs", message: "Required arguments missing", details: "\(call.method) requires 'id', 'dirIdentifier'"))
        return
    }
    guard var requestId = args["requestId"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'requestId'"))
        return
    }
    requestId = "\(jobTokenForId)\(requestId)"
    jobs.insert(requestId)
    defer {
        jobs.remove(requestId)
    }
    guard let orgId = args["orgId"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'orgId'"))
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

    let found = findFile(at: url, requestId: requestId) { file, name in
        guard name.hasSuffix(".org") || name.hasSuffix(".org.icloud") else {
            return false
        }
        logger.debug("Searching \(file) for ID \(orgId)")
        return withSecurityAccess(to: file) { fileUrl in
            var matched = false
            var fileError: NSError? = nil
            NSFileCoordinator().coordinate(readingItemAt: file, error: &fileError) { fileUrl in
                if fileContainsId(fileUrl: fileUrl, id: orgId) {
                    matched = true
                }
            }
            if let fileError = fileError {
                logger.error("Error accessing file: \(fileError)")
            }
            return matched
        }
    }

    guard let found = found else {
        DispatchQueue.main.async { result(nil) }
        return
    }

    let bookmark = withSecurityAccess(to: found) { url in
        return try? url.bookmarkData()
    }
    guard let bookmark = bookmark else {
        logger.info("Failed to get bookmark for file: \(found)")
        DispatchQueue.main.async { result(nil) }
        return
    }
    DispatchQueue.main.async {
        // Result compatible with file_picker_writable
        result([
            "path": found.path,
            "identifier": bookmark.base64EncodedString(),
            "persistable": "true",
            "uri": found.absoluteString,
            "fileName": found.lastPathComponent,
        ])
    }
}

private func findFileWithNamePrefix(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String:Any?] else {
        result(FlutterError(code: "MissingArgs", message: "Required arguments missing", details: "\(call.method) requires 'id', 'dirIdentifier'"))
        return
    }
    guard var requestId = args["requestId"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'requestId'"))
        return
    }
    requestId = "\(jobTokenForNamePrefix)\(requestId)"
    jobs.insert(requestId)
    defer {
        jobs.remove(requestId)
    }
    guard let namePrefix = args["namePrefix"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'namePrefix'"))
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

    let found = findFile(at: url, requestId: requestId) { file, name  in
        guard name.hasSuffix(".org") || name.hasSuffix(".org.icloud") else {
            return false
        }
        logger.debug("Searching \(file) for file name prefix \(namePrefix)")
        return name.hasPrefix(namePrefix)
    }

    guard let found = found else {
        DispatchQueue.main.async { result(nil) }
        return
    }

    let coordinated = withSecurityAccess(to: found) { url in
        var coordinated: URL? = nil
        var fileError: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, error: &fileError) { fileUrl in
            coordinated = fileUrl
        }
        if let fileError = fileError {
            logger.error("Error accessing file: \(fileError)")
        }
        return coordinated
    }

    guard let coordinated = coordinated else {
        DispatchQueue.main.async { result(nil) }
        return
    }

    let bookmark = withSecurityAccess(to: coordinated) { url in
        return try? url.bookmarkData()
    }
    guard let bookmark = bookmark else {
        logger.info("Failed to get bookmark for file: \(coordinated)")
        DispatchQueue.main.async { result(nil) }
        return
    }
    DispatchQueue.main.async {
        // Result compatible with file_picker_writable
        result([
            "path": coordinated.path,
            "identifier": bookmark.base64EncodedString(),
            "persistable": "true",
            "uri": coordinated.absoluteString,
            "fileName": coordinated.lastPathComponent,
        ])
    }
}

private func findFileWithExactName(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String:Any?] else {
        result(FlutterError(code: "MissingArgs", message: "Required arguments missing", details: "\(call.method) requires 'id', 'dirIdentifier'"))
        return
    }
    guard var requestId = args["requestId"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'requestId'"))
        return
    }
    requestId = "\(jobTokenForExactName)\(requestId)"
    jobs.insert(requestId)
    defer {
        jobs.remove(requestId)
    }
    guard let exactName = args["exactName"] as? String else {
        result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'exactName'"))
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

    let found = findFile(at: url, requestId: requestId) { file, name  in
        logger.debug("Searching \(file) for file named \(exactName)")
        return name == exactName
    }

    guard let found = found else {
        DispatchQueue.main.async { result(nil) }
        return
    }

    let coordinated = withSecurityAccess(to: found) { url in
        var coordinated: URL? = nil
        var fileError: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, error: &fileError) { fileUrl in
            coordinated = fileUrl
        }
        if let fileError = fileError {
            logger.error("Error accessing file: \(fileError)")
        }
        return coordinated
    }

    guard let coordinated = coordinated else {
        DispatchQueue.main.async { result(nil) }
        return
    }

    let bookmark = withSecurityAccess(to: coordinated) { url in
        return try? url.bookmarkData()
    }
    guard let bookmark = bookmark else {
        logger.info("Failed to get bookmark for file: \(coordinated)")
        DispatchQueue.main.async { result(nil) }
        return
    }
    DispatchQueue.main.async {
        // Result compatible with file_picker_writable
        result([
            "path": coordinated.path,
            "identifier": bookmark.base64EncodedString(),
            "persistable": "true",
            "uri": coordinated.absoluteString,
            "fileName": coordinated.lastPathComponent,
        ])
    }
}

private func findFile(at url: URL, requestId: String, predicate: (_ fileUrl: URL, _ name: String) -> Bool) -> URL?  {
    // https://developer.apple.com/documentation/uikit/view_controllers/providing_access_to_directories

    guard url.startAccessingSecurityScopedResource() else {
        logger.error("Failed to access security scoped resource: \(url)")
        return nil
    }

    defer { url.stopAccessingSecurityScopedResource() }

    var error: NSError? = nil
    var result: URL?
    NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { url in
        let keys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])

        guard let fileList =
                FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys)) else {
            logger.error("Failed to obtain enumerator")
            return
        }

        for case let file as URL in fileList {
            guard jobs.contains(requestId) else {
                logger.info("Quitting job \(requestId) due to cancellation")
                break
            }

            logger.debug("Looking at file \(file)")
            guard let values = try? file.resourceValues(forKeys: keys),
                  let isDirectory = values.isDirectory,
                  let name = values.name else {
                logger.error("Failed to access resource values: \(file)")
                continue
            }
            guard !isDirectory else {
                continue
            }
            if predicate(file, name) {
                result = file
                break
            }
        }
    }
    if let error = error {
        logger.error("Error accessing dir: \(error)")
    }
    return result
}

private let idPattern = try! NSRegularExpression(pattern: #"^\s*:ID:\s*(?<value>\S+)\s*$"#, options: [.caseInsensitive])

private func fileContainsId(fileUrl: URL, id: String) -> Bool {
    guard let reader = LineReader(url: fileUrl) else {
        logger.error("Failed to instantiate line reader")
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
    logger.debug("url: \(url) / isStale: \(isStale)")
    return url
}

class ConcurrentSet<T: Hashable> {
    private var data: Set<T> = []
    let lock = NSLock()

    func insert(_ item: T) {
        lock.lock()
        defer { lock.unlock() }
        data.insert(item)
    }

    func contains(_ item: T) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return data.contains(item)
    }

    @discardableResult
    func remove(_ item: T) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return data.remove(item)
    }
}

private func withSecurityAccess<T>(to url: URL, _ body: (URL) -> T) -> T {
    let accessing = url.startAccessingSecurityScopedResource()
    defer {
        if accessing {
            url.stopAccessingSecurityScopedResource()
        }
    }
    return body(url)
}
