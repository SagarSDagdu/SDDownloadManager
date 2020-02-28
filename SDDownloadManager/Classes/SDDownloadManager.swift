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

///Represents the completion handler that is called when a download finishes
public typealias CompletionHandler = (_ error : Error?, _ fileUrl:URL?) -> Void

///Represents the progress handler that is called periodically when a download progresses.
public typealias ProgressHandler = (_ progress : CGFloat) -> Void

//Represents the completion handler that is called when all background downloads complete.
public typealias BackgroundDownloadCompletionHandler = () -> Void

/// Represents a Error object that can be returned in the completionBlock in case any error occures while downloading a file
public enum SDDownloadError: Error {
    
    /// The supplied URLRequest doesn't contain a valid URL
    case invalidURL
    case raw(error: Error)
}

final public class SDDownloadManager: NSObject {
    
    // MARK:- Public Properties
    
    ///Called when all the background downloads are complete.
    public var backgroundCompletionHandler: BackgroundDownloadCompletionHandler?

    //MARK:- Private properties
    
    private var session: URLSession!
    private var downloaderConfiguration: SDDownloadManagerConfig
    private var sessionConfiguration: URLSessionConfiguration?
    
    private lazy var cache = [String:URL]()
    private lazy var ongoingDownloads: [String : SDDownloadModel] = [:]

    //MARK:- Public methods
    
    public init(withSessionIdentifier sessionIdentifier: String,
                sessionConfiguration: URLSessionConfiguration? = nil,
                downloaderConfiguration: SDDownloadManagerConfig = .defaultConfiguration,
                completion: (() -> Void)? = nil) {
        self.downloaderConfiguration = downloaderConfiguration
        self.sessionConfiguration = sessionConfiguration
        self.backgroundCompletionHandler = completion
        super.init()
        self.session = backgroundSession(identifier: sessionIdentifier, configuration: sessionConfiguration)
    }
    
    @discardableResult public func downloadFile(withRequest request: URLRequest,
                            atDestinationPath destinationPath: String? = nil,
                            withName fileName: String? = nil,
                            onProgress progressBlock:ProgressHandler? = nil,
                            onCompletion completionBlock:@escaping CompletionHandler) -> String? {
        
        ///Precheck for URL
        guard let url = request.url else {
            debugPrint("Request url is empty")
            completionBlock(SDDownloadError.invalidURL, nil)
            return nil
        }
        
        ///Is already in progress
        if let _ = ongoingDownloads[url.absoluteString] {
            debugPrint("Already in progress")
            return nil
        }
        
        let downloadTask = session.downloadTask(with: request)
        let downloadModel = SDDownloadModel(withTask: downloadTask, fileName: fileName, destinationPath: destinationPath)
        downloadModel.progressBlock = progressBlock
        downloadModel.completionBlock = completionBlock
        
        let key = getDownloadKey(withUrl: url)
        ongoingDownloads[key] = downloadModel
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
        ongoingDownloads.forEach { $1.downloadTask.cancel() }
        ongoingDownloads.removeAll()
    }
    
    public func cancelDownload(forUniqueKey key:String) {
        if let ongoingDownload = getOngoingDownload(forKey: key) {
            ongoingDownload.downloadTask.cancel()
            ongoingDownloads[key] = nil
        }
    }
    
    public func pause(forUniqueKey key:String) {
        if let ongoingDownload = getOngoingDownload(forKey: key) {
            ongoingDownload.downloadTask.suspend()
            ongoingDownloads[key] = nil
        }
    }
    
    public func resume(forUniqueKey key:String) {
        if let ongoingDownload = getOngoingDownload(forKey: key) {
            ongoingDownload.downloadTask.resume()
            ongoingDownloads[key] = nil
        }
    }
    
    //MARK:- Private methods
    
    private func backgroundSession(identifier: String,
                                       configuration: URLSessionConfiguration? = nil) -> URLSession {
        let sessionConfiguration = configuration ?? URLSessionConfiguration.background(withIdentifier: identifier)
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        return session
    }
    
    private func getOngoingDownload(forKey key: String) -> SDDownloadModel? {
        if let ongoingDownload = ongoingDownloads.first(where: { (taskKey, downloadModel) -> Bool in
            return key == taskKey
        }) {
            return ongoingDownload.value
        }
        return nil
    }
    
    private func showLocalNotification(withText text:String) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
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
            notificationCenter.add(request, withCompletionHandler: { (error) in
                if let error = error {
                    debugPrint("Could not schedule notification, error : \(error)")
                }
            })
        }
    }
}

extension SDDownloadManager : URLSessionDelegate, URLSessionDownloadDelegate {
    
    // MARK:- Delegates
    
    public func urlSession(_ session: URLSession,
                             downloadTask: URLSessionDownloadTask,
                             didFinishDownloadingTo location: URL) {
        
        guard let key = (downloadTask.originalRequest?.url?.absoluteString),
            let downloadModel = ongoingDownloads[key] else {
            return
        }
        
        if let response = downloadTask.response as? HTTPURLResponse,     !(200...299).contains(response.statusCode) {
            let error = NSError(domain:"HttpError", code: response.statusCode, userInfo:[NSLocalizedDescriptionKey : HTTPURLResponse.localizedString(forStatusCode: response.statusCode)])
            MainQueue {
                downloadModel.completionBlock?(SDDownloadError.raw(error: error), nil)
                return
            }
        }
        
        let fileName = downloadModel.fileName ?? downloadTask.response?.suggestedFilename ?? (downloadTask.originalRequest?.url?.lastPathComponent) ?? "UnknownFile"
        
        if let locationDirectory = downloadModel.destinationPath {
            debugPrint("destination supplied by user: \(locationDirectory) ")
            //TODO 1) Move the file to user supplied directory
            //     2) Hande directory not present condition
        } else {
            let fileMovingResult = SDFileUtils.moveFile(fromUrl: location, toDirectory: nil, withName: fileName)
            let didSucceed = fileMovingResult.0
            let error = fileMovingResult.1
            let finalFileUrl = fileMovingResult.2
            
            MainQueue { [weak self] in
                if !didSucceed, let error = error  {
                    downloadModel.completionBlock?(error, nil)
                } else {
                    downloadModel.completionBlock?(nil, finalFileUrl)
                    if let fileUrl = finalFileUrl, self?.isCachingEnabled() == true {
                        self?.writeToCache(for: key, url: fileUrl)
                    }
                }
            }
        }
        
        ongoingDownloads[key] = nil
    }
    
    public func urlSession(_ session: URLSession,
                             downloadTask: URLSessionDownloadTask,
                             didWriteData bytesWritten: Int64,
                             totalBytesWritten: Int64,
                             totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else {
            debugPrint("Could not calculate progress as totalBytesExpectedToWrite is less than 0")
            return;
        }
        
        if let key = downloadTask.originalRequest?.url?.absoluteString,
            let download = ongoingDownloads[key],
            let progressBlock = download.progressBlock {
            let progress : CGFloat = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
            MainQueue {
                progressBlock(progress)
            }
        }
    }
    
    public func urlSession(_ session: URLSession,
                             task: URLSessionTask,
                             didCompleteWithError error: Error?) {
        
        let key = task.originalRequest?.url?.absoluteString
        
        if let error = error,
            let key = key,
            let download = ongoingDownloads[key] {
                MainQueue {
                    download.completionBlock?(SDDownloadError.raw(error: error), nil)
                }
            }
        if let key = key { ongoingDownloads[key] = nil }
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in
            if downloadTasks.count == 0 {
                MainQueue { [weak self] in
                    if let completion = self?.backgroundCompletionHandler {
                        completion()
                    }
                    
                    guard let downloaderConfiguration = self?.downloaderConfiguration, downloaderConfiguration.shouldShowNotificationOnDone else {
                        self?.backgroundCompletionHandler = nil
                        return
                    }
                    
                    self?.showLocalNotification(withText: downloaderConfiguration.localNotificationText)
                    self?.backgroundCompletionHandler = nil
                }
            }
        }
    }
}


extension SDDownloadManager {
    
    ///Checks with the config supplied whether caching is enabled
    private func isCachingEnabled() -> Bool {
        return true
    }
    
    ///Returns the destination URL from the cache for the specified identifier
    private func getCachedLocation(for identifer: String) -> URL? {
        return cache[identifer]
    }
    
    ///Writes to cache
    private func writeToCache(for identifier: String, url: URL) {
        cache[identifier] = url
    }
}
