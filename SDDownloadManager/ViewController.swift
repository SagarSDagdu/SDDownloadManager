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
    
    let directoryName : String = "TestDirectory"
    
    //MARK:- Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressView.setProgress(0, animated: false)
        self.progressLabel.text = "0.0 %"
        self.finalUrlLabel.text = ""
        
        let request = URLRequest.init(url: URL.init(string: "http://www.sample-videos.com/video/3gp/144/big_buck_bunny_144p_5mb.3gp")!)
        
        let downloadKey = SDDownloadManager.shared.dowloadFile(withRequest: request,
                                                               inDirectory: directoryName,
                                                               withName: nil,
                                                               onProgress:  { [weak self] (progress) in
                                                                let percentage = String(format: "%.1f %", (progress * 100))
                                                                self?.progressView.setProgress(Float(progress), animated: true)
                                                                self?.progressLabel.text = "\(percentage) %"
        }) { [weak self] (error, url) in
            if let error = error {
                print("Error is \(error as NSError)")
            } else {
                if let url = url {
                    print("Downloaded file's url is \(url.path)")
                    self?.finalUrlLabel.text = url.path
                }
            }
        }
        
        print("The key is \(downloadKey!)")
        
        
    }
    

}

