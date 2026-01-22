//
//  Constants.swift
//  OC Build Wizard
//
//  Copyright (C) 2024 - 2026 Mirone. All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

enum Constants {
    
    // MARK: - Paths
    
    enum Paths {
        static let logDirectory = "/tmp"
        static let localBinPath = "/usr/local/bin"
        
        static let requiredTools = [
            "\(localBinPath)/nasm",
            "\(localBinPath)/mtoc",
            "\(localBinPath)/iasl",
            "\(localBinPath)/ndisasm"
        ]
    }
    
    // MARK: - Commands
    
    enum Commands {
        static let shellPath = "/bin/zsh"
        static let buildEnvironment = "PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        static let openCoreVersionCommand = "nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}'"
    }
    
    // MARK: - Git
    
    enum Git {
        static let defaultBranch = "master"
    }
    
    // MARK: - UI
    
    enum UI {
        static let progressAnimationDelay: TimeInterval = 0.1
    }
    
    // MARK: - App Info
    
    enum App {
        static let name = "OC Build Wizard"
        static let logFilePrefix = "OC Build Wizard"
        
        static var version: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        }
        
        static var buildNumber: String {
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        }
    }
}
