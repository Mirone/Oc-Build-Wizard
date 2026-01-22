//
//  NetworkService.swift
//  OC Build Wizard
//
//  Copyright (C) 2024 - 2026 Mirone. All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import SystemConfiguration

protocol NetworkServiceProtocol {
    func isConnectedToNetwork() -> Bool
}

final class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    
    // MARK: - Public Methods
    
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let reachability = createReachability(from: &zeroAddress) else {
            return false
        }
        
        var flags = SCNetworkReachabilityFlags()
        guard SCNetworkReachabilityGetFlags(reachability, &flags) else {
            return false
        }
        
        return isReachable(with: flags)
    }
    
    // MARK: - Private Methods
    
    private func createReachability(from address: inout sockaddr_in) -> SCNetworkReachability? {
        return withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                SCNetworkReachabilityCreateWithAddress(nil, sockaddrPointer)
            }
        }
    }
    
    private func isReachable(with flags: SCNetworkReachabilityFlags) -> Bool {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return isReachable && !needsConnection
    }
}
