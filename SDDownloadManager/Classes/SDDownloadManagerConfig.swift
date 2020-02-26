//
//  SDDownloadManagerConfig.swift
//  SDDownloadManager
//
//  Created by Sagar Dagdu on 2/25/20.
//  Copyright © 2020 Sagar Dagdu. All rights reserved.
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

///This class represents the configuration set for the download manager object
final public class SDDownloadManagerConfig {
    
    //MARK:- Public
    
    /// If set, a local notification is shown when all the downloads are complete
    public var shouldShowNotificationOnDone = false
    
    /// The text which is shown on the local notification when the download is complete
    public var localNotificationText: String = "All downloads completed"
    
    /// If set, the download manager uses a cache where the key is the URL used for downloading
    public var shouldUseCache = true
    
    ///Returns a default configuration object
    public class var defaultConfiguration: SDDownloadManagerConfig {
        get {
            let config = SDDownloadManagerConfig()
            return config
        }
    }
    
}
