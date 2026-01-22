//
//  BuildConfiguration.swift
//  OC Build Wizard
//
//  Copyright (C) 2024 - 2026 Mirone. All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

struct BuildConfiguration {
    let repositoryType: RepositoryType
    let startTime: Date
    
    init(repositoryType: RepositoryType) {
        self.repositoryType = repositoryType
        self.startTime = Date()
    }
    
    var elapsedTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    
    var formattedElapsedTime: String {
        let elapsed = elapsedTime
        let hours = Int(elapsed / 3600)
        let minutes = Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(elapsed.truncatingRemainder(dividingBy: 60))
        
        return "\(hours) hours, \(minutes) minutes, \(seconds) seconds."
    }
}
