//
//  GlobalUtils.swift
//  SDDownloadManager
//
//  Created by Sagar Dagdu on 2/25/20.
//  Copyright © 2020 Sagar Dagdu. All rights reserved.
//

import Foundation

/// Executes the given block on main queue
public func MainQueue(block: @escaping () -> Void) {
    DispatchQueue.main.async {
        block()
    }
}

/// Executes the given block on global background queue
public func BackgroundQueue(block: @escaping () -> Void) {
    DispatchQueue.global(qos: .background).async {
        block()
    }
}
