//
//  LineReader.swift
//  Runner
//
//  Created by Aaron Madlon-Kay on 2021/06/03.
//  Adapted from https://github.com/andrewwoz/LineReader

// Copyright © 2017 andrewwoz, 2024 Aaron Madlon-Kay

import Foundation

/// Read text file line by line in efficient way
public class LineReader {
    public let path: String

    fileprivate let file: UnsafeMutablePointer<FILE>!

    init?(path: String) {
        self.path = path
        file = fopen(path, "r")
        guard file != nil else { return nil }
    }

    init?(url: URL) {
        if (!url.isFileURL) { return nil }
        self.path = url.path
        file = url.withUnsafeFileSystemRepresentation { path in
            fopen(path, "r")
        }
        guard file != nil else { return nil }
    }

    public var nextLine: String? {
        var line:UnsafeMutablePointer<CChar>? = nil
        var linecap:Int = 0
        defer { if (line != nil) { free(line!) } }
        return getline(&line, &linecap, file) > 0 ? String(cString: line!) : nil
    }

    deinit {
        fclose(file)
    }
}

extension LineReader: Sequence {
    public func  makeIterator() -> AnyIterator<String> {
        return AnyIterator<String> {
            return self.nextLine
        }
    }
}
