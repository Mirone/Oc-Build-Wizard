//
//  Repository.swift
//  OC Build Wizard
//
//  Copyright (C) 2024 - 2026 Mirone. All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

enum RepositoryType: Int {
    case acidanthera = 1
    case btwise = 2
    
    var name: String {
        switch self {
        case .acidanthera: return "OpenCorePkg"
        case .btwise: return "OpenCore_No_ACPI"
        }
    }
    
    var url: String {
        switch self {
        case .acidanthera: return "https://github.com/acidanthera/OpenCorePkg.git"
        case .btwise: return "https://gitee.com/btwise/OpenCore_NO_ACPI.git"
        }
    }
    
    var buildScriptName: String {
        switch self {
        case .acidanthera: return "build_oc.tool"
        case .btwise: return "build_oc_en.tool"
        }
    }
    
    var binariesPath: String {
        "\(NSHomeDirectory())/\(name)/Binaries"
    }
    
    var localPath: String {
        "\(NSHomeDirectory())/\(name)"
    }
    
    var localURL: URL {
        URL(fileURLWithPath: localPath)
    }
    
    var exists: Bool {
        FileManager.default.fileExists(atPath: localPath)
    }
}
