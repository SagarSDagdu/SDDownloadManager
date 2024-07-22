//
//  SDFileUtils.swift
//  SDDownloadManager
//
//  Created by Sagar Dagdu on 8/5/17.
//  Copyright © 2017 Sagar Dagdu. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

class SDFileUtils: NSObject {
    // MARK: - Helpers

    static func moveFile(fromUrl url: URL,
                         toDirectory directory: String?,
                         withName name: String) -> (Bool, Error?, URL?)
    {
        guard !name.isEmpty else {
            return (false, NSError(domain: "SDFileUtils", code: 1, userInfo: [NSLocalizedDescriptionKey: "File name cannot be empty"]), nil)
        }

        let newUrl: URL
        if let directory = directory, !directory.isEmpty {
            let directoryCreationResult = createDirectoryIfNotExists(withName: directory)
            guard directoryCreationResult.0 else {
                return (false, directoryCreationResult.1, nil)
            }
            newUrl = cacheDirectoryPath().appendingPathComponent(directory).appendingPathComponent(name)
        } else {
            newUrl = cacheDirectoryPath().appendingPathComponent(name)
        }

        do {
            if FileManager.default.fileExists(atPath: newUrl.path) {
                try FileManager.default.removeItem(at: newUrl)
            }
            try FileManager.default.moveItem(at: url, to: newUrl)
            return (true, nil, newUrl)
        } catch {
            return (false, error, nil)
        }
    }

    static func cacheDirectoryPath() -> URL {
        let cachePaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        guard let cachePath = cachePaths.first else {
            // If we can't get the cache directory, fall back to the temporary directory
            return FileManager.default.temporaryDirectory
        }
        return URL(fileURLWithPath: cachePath)
    }

    static func createDirectoryIfNotExists(withName name: String) -> (Bool, Error?) {
        guard !name.isEmpty else {
            return (false, NSError(domain: "SDFileUtils", code: 2, userInfo: [NSLocalizedDescriptionKey: "Directory name cannot be empty"]))
        }

        let directoryUrl = cacheDirectoryPath().appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: directoryUrl.path) {
            return (true, nil)
        }
        do {
            try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
            return (true, nil)
        } catch {
            return (false, error)
        }
    }
}
