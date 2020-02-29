//
//  Cache.swift
//  SDDownloadManager
//
//  Created by Sagar Dagdu on 2/29/20.
//  Copyright © 2020 Sagar Dagdu. All rights reserved.
//

import UIKit


protocol Cache {
    associatedtype Key where Key: Hashable
    associatedtype Value
    
    func write(key: Key, value: Value, expiration: TimeInterval)
    func getValue(for key: Key) -> Value?
}


class FileCache: Cache {
    
    typealias Key = String
    typealias Value = URL
    
    private var fileManager: FileManager
    
    init(withFileManager fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func write(key: String, value: URL, expiration: TimeInterval) {
        
    }
    
    func getValue(for key: String) -> URL? {
        return nil
    }
    
}
