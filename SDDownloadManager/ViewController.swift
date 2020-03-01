//
//  ViewController.swift
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

class ViewController: UIViewController {

    //MARK:- Properties
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var finalUrlLabel: UILabel!
    
    private var downloadManager: SDDownloadManager!
    
    let directoryName : String = "TestDirectory"
    
    let fiveMBUrl = "https://sample-videos.com/video123/mp4/480/big_buck_bunny_480p_5mb.mp4"
    let tenMBUrl = "https://sample-videos.com/video123/mp4/480/big_buck_bunny_480p_10mb.mp4"
    
    //MARK:- Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupDownloadManager()
        downloadDemo()
    }
    
    private func setupUI() {
        self.progressView.setProgress(0, animated: false)
        self.progressLabel.text = "0.0 %"
        self.finalUrlLabel.text = ""
    }
    
    private func setupDownloadManager() {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let backgroundCompletion = (UIApplication.shared.delegate as? AppDelegate)?.backgroundSessionCompletionHandler
        downloadManager = SDDownloadManager(withSessionIdentifier: bundleIdentifier, completion: backgroundCompletion)
    }
    
    
    private func downloadDemo() {
        let request = URLRequest(url: URL(string: self.tenMBUrl)!)
        let destination = (documentsDirectoryPath() as NSString).appendingPathComponent("SampleDownload")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: destination) {
            do {
            try fileManager.createDirectory(atPath: destination, withIntermediateDirectories: true, attributes: [:])
            } catch {
                print("Error while creating directory")
            }
        }
        
        downloadManager.downloadFile(withRequest: request, atDestinationPath: destination, withName: nil, onProgress: { [weak self] (progress) in
            self?.setProgress(progress: progress)
        }) { [weak self] (error, url) in
            if let error = error {
                print("Error is \(error)")
            } else {
                if let url = url {
                    print("Downloaded file's url is \(url.path)")
                    self?.finalUrlLabel.text = url.path
                }
            }
        }
    }
    
    //MARK:- Helpers
    
    private func setProgress(progress: CGFloat) {
        let percentage = String(format: "%.1f %", (progress * 100))
        self.progressView.setProgress(Float(progress), animated: true)
        self.progressLabel.text = "\(percentage) %"
    }
    
    private func documentsDirectoryPath() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }

}

