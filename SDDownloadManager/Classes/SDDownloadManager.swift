//
//  SDDownloadManager.swift
//  SDDownloadManager
//
//  Created by Sagar Dagdu on 8/4/17.
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
import UserNotifications

public final class SDDownloadManager: NSObject {
    public typealias DownloadCompletionBlock = (_ error: Error?, _ fileUrl: URL?) -> Void
    public typealias DownloadProgressBlock = (_ progress: CGFloat) -> Void
    public typealias BackgroundDownloadCompletionHandler = () -> Void

    // MARK: - Properties

    private var session: URLSession!
    private let downloadQueue = DispatchQueue(label: "com.sddownloadmanager.queue", attributes: .concurrent)
    private var _ongoingDownloads: [String: SDDownloadObject] = [:]
    private var ongoingDownloads: [String: SDDownloadObject] {
        get {
            return downloadQueue.sync { _ongoingDownloads }
        }
        set {
            downloadQueue.async(flags: .barrier) {
                self._ongoingDownloads = newValue
            }
        }
    }

    private var backgroundSession: URLSession!

    public var backgroundCompletionHandler: BackgroundDownloadCompletionHandler?
    public var showLocalNotificationOnBackgroundDownloadDone = true
    public var localNotificationText: String?

    public static let shared = SDDownloadManager()

    // MARK: - Public methods

    public func downloadFile(withRequest request: URLRequest,
                             inDirectory directory: String? = nil,
                             withName fileName: String? = nil,
                             shouldDownloadInBackground: Bool = false,
                             onProgress progressBlock: DownloadProgressBlock? = nil,
                             onCompletion completionBlock: @escaping DownloadCompletionBlock) -> String?
    {
        guard let url = request.url else {
            completionBlock(NSError(domain: "SDDownloadManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]), nil)
            return nil
        }

        let key = getDownloadKey(withUrl: url)

        if isDownloadInProgress(forKey: key) {
            completionBlock(NSError(domain: "SDDownloadManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Download already in progress"]), nil)
            return nil
        }

        let downloadTask: URLSessionDownloadTask
        if shouldDownloadInBackground {
            downloadTask = backgroundSession.downloadTask(with: request)
        } else {
            downloadTask = session.downloadTask(with: request)
        }

        let download = SDDownloadObject(downloadTask: downloadTask,
                                        progressBlock: progressBlock,
                                        completionBlock: completionBlock,
                                        fileName: fileName,
                                        directoryName: directory)

        downloadQueue.async(flags: .barrier) {
            self._ongoingDownloads[key] = download
        }
        downloadTask.resume()
        return key
    }

    public func getDownloadKey(withUrl url: URL) -> String {
        return url.absoluteString
    }

    public func currentDownloads() -> [String] {
        return downloadQueue.sync { Array(_ongoingDownloads.keys) }
    }

    public func cancelAllDownloads() {
        downloadQueue.async(flags: .barrier) {
            for (_, download) in self._ongoingDownloads {
                download.downloadTask.cancel()
            }
            self._ongoingDownloads.removeAll()
        }
    }

    public func cancelDownload(forUniqueKey key: String?) {
        guard let key = key else { return }

        downloadQueue.async(flags: .barrier) {
            if let download = self._ongoingDownloads[key] {
                download.downloadTask.cancel()
                self._ongoingDownloads.removeValue(forKey: key)
            }
        }
    }

    public func pause(forUniqueKey key: String?) {
        guard let key = key else { return }

        downloadQueue.async {
            self._ongoingDownloads[key]?.downloadTask.suspend()
        }
    }

    public func resume(forUniqueKey key: String?) {
        guard let key = key else { return }

        downloadQueue.async {
            self._ongoingDownloads[key]?.downloadTask.resume()
        }
    }

    public func isDownloadInProgress(forKey key: String?) -> Bool {
        guard let key = key else { return false }
        return downloadQueue.sync { _ongoingDownloads[key] != nil }
    }

    public func alterDownload(withKey key: String?,
                              onProgress progressBlock: DownloadProgressBlock?,
                              onCompletion completionBlock: @escaping DownloadCompletionBlock)
    {
        guard let key = key else { return }

        downloadQueue.async(flags: .barrier) {
            if let download = self._ongoingDownloads[key] {
                download.progressBlock = progressBlock
                download.completionBlock = completionBlock
                self._ongoingDownloads[key] = download
            }
        }
    }

    // MARK: - Private methods

    override private init() {
        super.init()
        let sessionConfiguration = URLSessionConfiguration.default
        session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: Bundle.main.bundleIdentifier!)
        backgroundSession = URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: OperationQueue())
    }

    private func showLocalNotification(withText text: String) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Not authorized to schedule notification")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = text
            content.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let identifier = "SDDownloadManagerNotification"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Could not schedule notification, error: \(error)")
                }
            }
        }
    }
}

extension SDDownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    public func urlSession(_: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL)
    {
        guard let key = downloadTask.originalRequest?.url?.absoluteString,
              let download = downloadQueue.sync(execute: { _ongoingDownloads[key] })
        else {
            return
        }

        if let response = downloadTask.response as? HTTPURLResponse {
            let statusCode = response.statusCode

            guard statusCode < 400 else {
                let error = NSError(domain: "HttpError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: statusCode)])
                DispatchQueue.main.async {
                    download.completionBlock(error, nil)
                }
                return
            }

            let fileName = download.fileName ?? response.suggestedFilename ?? downloadTask.originalRequest?.url?.lastPathComponent ?? "unknown"
            let directoryName = download.directoryName

            let fileMovingResult = SDFileUtils.moveFile(fromUrl: location, toDirectory: directoryName, withName: fileName)
            let didSucceed = fileMovingResult.0
            let error = fileMovingResult.1
            let finalFileUrl = fileMovingResult.2

            DispatchQueue.main.async {
                didSucceed ? download.completionBlock(nil, finalFileUrl) : download.completionBlock(error, nil)
            }
        }

        downloadQueue.async(flags: .barrier) {
            self._ongoingDownloads.removeValue(forKey: key)
        }
    }

    public func urlSession(_: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData _: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64)
    {
        guard totalBytesExpectedToWrite > 0 else {
            print("Could not calculate progress as totalBytesExpectedToWrite is less than or equal to 0")
            return
        }

        guard let key = downloadTask.originalRequest?.url?.absoluteString,
              let download = downloadQueue.sync(execute: { _ongoingDownloads[key] }),
              let progressBlock = download.progressBlock
        else {
            return
        }

        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            progressBlock(progress)
        }
    }

    public func urlSession(_: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?)
    {
        guard let error = error,
              let downloadTask = task as? URLSessionDownloadTask,
              let key = downloadTask.originalRequest?.url?.absoluteString,
              let download = downloadQueue.sync(execute: { _ongoingDownloads[key] })
        else {
            return
        }

        DispatchQueue.main.async {
            download.completionBlock(error, nil)
        }

        downloadQueue.async(flags: .barrier) {
            self._ongoingDownloads.removeValue(forKey: key)
        }
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        session.getTasksWithCompletionHandler { _, _, downloadTasks in
            if downloadTasks.isEmpty {
                DispatchQueue.main.async {
                    self.backgroundCompletionHandler?()

                    if self.showLocalNotificationOnBackgroundDownloadDone {
                        let notificationText = self.localNotificationText ?? "Download completed"
                        self.showLocalNotification(withText: notificationText)
                    }

                    self.backgroundCompletionHandler = nil
                }
            }
        }
    }
}
