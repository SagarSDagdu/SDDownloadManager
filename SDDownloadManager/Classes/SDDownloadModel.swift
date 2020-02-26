//
//  SDDownloadObject.swift
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

import Foundation

/// Represents a download.
final class SDDownloadModel {

    //MARK:- Public
    
    /// Called when the download is completed. If no error occurs, then the second parameter passed is the URL of the downloaded file
    var completionBlock: CompletionHandler? = nil
    
    /// Called when the download progresses. The progress is a ```CGFloat```
    var progressBlock: ProgressHandler? = nil
    
    /// The download task associated with this model
    var downloadTask: URLSessionDownloadTask
    
    /// The destination directory path where the downloaded file should be moved
    var destinationPath: String? = nil
    
    /// The fileName to be used when the download is complete.
    var fileName:String? = nil
    
    //MARK:- Initialization
    
    init(withTask downloadTask: URLSessionDownloadTask,
         fileName: String?,
         destinationPath: String?) {
        self.downloadTask = downloadTask
        self.fileName = fileName
        self.destinationPath = destinationPath
    }
    
}
