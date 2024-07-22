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
    private var ongoingDownloads: [String: SDDownloadObject] = [:]
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
            debugPrint("Request url is empty")
            return nil
        }

        if let _ = ongoingDownloads[url.absoluteString] {
            debugPrint("Already in progress")
            return nil
        }

        var downloadTask: URLSessionDownloadTask
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

        let key = getDownloadKey(withUrl: url)
        ongoingDownloads[key] = download
        downloadTask.resume()
        return key
    }

    public func getDownloadKey(withUrl url: URL) -> String {
        return url.absoluteString
    }

    public func currentDownloads() -> [String] {
        return Array(ongoingDownloads.keys)
    }

    public func cancelAllDownloads() {
        for (_, download) in ongoingDownloads {
            let downloadTask = download.downloadTask
            downloadTask.cancel()
        }
        ongoingDownloads.removeAll()
    }

    public func cancelDownload(forUniqueKey key: String?) {
        let downloadStatus = isDownloadInProgress(forUniqueKey: key)
        let presence = downloadStatus.0
        if presence {
            if let download = downloadStatus.1 {
                download.downloadTask.cancel()
                ongoingDownloads.removeValue(forKey: key!)
            }
        }
    }

    public func pause(forUniqueKey key: String?) {
        let downloadStatus = isDownloadInProgress(forUniqueKey: key)
        let presence = downloadStatus.0
        if presence {
            if let download = downloadStatus.1 {
                let downloadTask = download.downloadTask
                downloadTask.suspend()
            }
        }
    }

    public func resume(forUniqueKey key: String?) {
        let downloadStatus = isDownloadInProgress(forUniqueKey: key)
        let presence = downloadStatus.0
        if presence {
            if let download = downloadStatus.1 {
                let downloadTask = download.downloadTask
                downloadTask.resume()
            }
        }
    }

    public func isDownloadInProgress(forKey key: String?) -> Bool {
        let downloadStatus = isDownloadInProgress(forUniqueKey: key)
        return downloadStatus.0
    }

    public func alterDownload(withKey key: String?,
                              onProgress progressBlock: DownloadProgressBlock?,
                              onCompletion completionBlock: @escaping DownloadCompletionBlock)
    {
        let downloadStatus = isDownloadInProgress(forUniqueKey: key)
        let presence = downloadStatus.0
        if presence {
            if let download = downloadStatus.1 {
                download.progressBlock = progressBlock
                download.completionBlock = completionBlock
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

    private func isDownloadInProgress(forUniqueKey key: String?) -> (Bool, SDDownloadObject?) {
        guard let key = key else { return (false, nil) }
        for (uniqueKey, download) in ongoingDownloads {
            if key == uniqueKey {
                return (true, download)
            }
        }
        return (false, nil)
    }

    private func showLocalNotification(withText text: String) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                debugPrint("Not authorized to schedule notification")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = text
            content.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1,
                                                            repeats: false)
            let identifier = "SDDownloadManagerNotification"
            let request = UNNotificationRequest(identifier: identifier,
                                                content: content, trigger: trigger)
            notificationCenter.add(request, withCompletionHandler: { error in
                if let error = error {
                    debugPrint("Could not schedule notification, error : \(error)")
                }
            })
        }
    }
}

extension SDDownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    // MARK: - Delegates

    public func urlSession(_: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL)
    {
        let key = (downloadTask.originalRequest?.url?.absoluteString)!
        if let download = ongoingDownloads[key] {
            if let response = downloadTask.response {
                let statusCode = (response as! HTTPURLResponse).statusCode

                guard statusCode < 400 else {
                    let error = NSError(domain: "HttpError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: statusCode)])
                    OperationQueue.main.addOperation {
                        download.completionBlock(error, nil)
                    }
                    return
                }
                let fileName = download.fileName ?? downloadTask.response?.suggestedFilename ?? (downloadTask.originalRequest?.url?.lastPathComponent)!
                let directoryName = download.directoryName

                let fileMovingResult = SDFileUtils.moveFile(fromUrl: location, toDirectory: directoryName, withName: fileName)
                let didSucceed = fileMovingResult.0
                let error = fileMovingResult.1
                let finalFileUrl = fileMovingResult.2

                OperationQueue.main.addOperation {
                    didSucceed ? download.completionBlock(nil, finalFileUrl) : download.completionBlock(error, nil)
                }
            }
        }
        ongoingDownloads.removeValue(forKey: key)
    }

    public func urlSession(_: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData _: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64)
    {
        guard totalBytesExpectedToWrite > 0 else {
            debugPrint("Could not calculate progress as totalBytesExpectedToWrite is less than 0")
            return
        }

        if let download = ongoingDownloads[(downloadTask.originalRequest?.url?.absoluteString)!],
           let progressBlock = download.progressBlock
        {
            let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
            OperationQueue.main.addOperation {
                progressBlock(progress)
            }
        }
    }

    public func urlSession(_: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?)
    {
        if let error = error {
            let downloadTask = task as! URLSessionDownloadTask
            let key = (downloadTask.originalRequest?.url?.absoluteString)!
            if let download = ongoingDownloads[key] {
                OperationQueue.main.addOperation {
                    download.completionBlock(error, nil)
                }
            }
            ongoingDownloads.removeValue(forKey: key)
        }
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        session.getTasksWithCompletionHandler { _, _, downloadTasks in
            if downloadTasks.count == 0 {
                OperationQueue.main.addOperation {
                    if let completion = self.backgroundCompletionHandler {
                        completion()
                    }

                    if self.showLocalNotificationOnBackgroundDownloadDone {
                        var notificationText = "Download completed"
                        if let userNotificationText = self.localNotificationText {
                            notificationText = userNotificationText
                        }

                        self.showLocalNotification(withText: notificationText)
                    }

                    self.backgroundCompletionHandler = nil
                }
            }
        }
    }
}
