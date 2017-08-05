//
//  ViewController.swift
//  SDDownloadManager
//
//  Created by Sagar Dagdu on 8/5/17.
//  Copyright © 2017 Sagar Dagdu. All rights reserved.
//

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
        
        self.progressView.setProgress(0, animated: true)
        self.progressLabel.text = "0"
        
        let request = URLRequest.init(url: URL.init(string: "http://www.sample-videos.com/video/3gp/144/big_buck_bunny_144p_5mb.3gp")!)
        
        let downloadKey = SDDownloadManager.shared.dowloadFile(withRequest: request,
                                                               inDirectory: directoryName,
                                                               withName: nil,
                                                               onProgress:  { [weak self] (progress) in
                                                                self?.progressView.setProgress(Float(progress), animated: true)
                                                                self?.progressLabel.text = "\(progress)"
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

