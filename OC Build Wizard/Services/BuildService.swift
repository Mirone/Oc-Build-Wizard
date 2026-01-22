//
//  BuildService.swift
//  OC Build Wizard
//
//  Copyright (C) 2024 - 2026 Mirone. All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import Cocoa

enum BuildError: LocalizedError {
    case toolsNotFound(missing: [String])
    case copyFailed(reason: String)
    case buildFailed(underlying: Error)
    case userCanceled
    case scriptNotFound(path: String)
    
    var errorDescription: String? {
        switch self {
        case .toolsNotFound(let missing):
            return "Required tools not found: \(missing.joined(separator: ", "))"
        case .copyFailed(let reason):
            return "Failed to copy required files: \(reason)"
        case .buildFailed(let error):
            return "Build failed: \(error.localizedDescription)"
        case .userCanceled:
            return "Build canceled by user"
        case .scriptNotFound(let path):
            return "Build script not found at: \(path)"
        }
    }
}

protocol BuildServiceProtocol {
    func checkRequiredTools() throws
    func buildOpenCore(config: BuildConfiguration, outputTextView: NSTextView?, completion: @escaping (Result<String, Error>) -> Void)
}

final class BuildService: BuildServiceProtocol {
    
    // MARK: - Constants
    
    private enum Constants {
        static let requiredTools = [
            "/usr/local/bin/nasm",
            "/usr/local/bin/mtoc",
            "/usr/local/bin/iasl",
            "/usr/local/bin/ndisasm"
        ]
        
        static let buildEnvironment = "PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    }
    
    // MARK: - Properties
    
    private let shellService: ShellServiceProtocol
    private let fileManager: FileManager
    
    // MARK: - Initialization
    
    init(shellService: ShellServiceProtocol, fileManager: FileManager = .default) {
        self.shellService = shellService
        self.fileManager = fileManager
    }
    
    // MARK: - Public Methods
    
    func checkRequiredTools() throws {
        let missingTools = findMissingTools()
        
        guard !missingTools.isEmpty else { return }
        
        try copyRequiredTools(missing: missingTools)
    }
    
    func buildOpenCore(config: BuildConfiguration, outputTextView: NSTextView?, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let scriptPath = try self.prepareAndCopyBuildScript(for: config.repositoryType)
                try self.executeBuildScript(at: scriptPath, outputTextView: outputTextView)
                
                DispatchQueue.main.async {
                    completion(.success(config.repositoryType.binariesPath))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(BuildError.buildFailed(underlying: error)))
                }
            }
        }
    }
    
    // MARK: - Private Methods - Tool Management
    
    private func findMissingTools() -> [String] {
        return Constants.requiredTools.filter { !fileManager.fileExists(atPath: $0) }
    }
    
    private func copyRequiredTools(missing: [String]) throws {
        guard let resourcePath = Bundle.main.resourcePath else {
            throw BuildError.copyFailed(reason: "Bundle resource path not found")
        }
        
        let binsPath = (resourcePath as NSString).appendingPathComponent("Bins")
        let copyCommand = "mkdir -p /usr/local/bin; cp -R \"\(binsPath)\"/* /usr/local/bin"
        
        let result = Authorization.executeWithPrivileges(.pathArgs(path: "/bin/sh", args: ["-c", copyCommand]))
        
        switch result {
        case .success(let fileHandle):
            try? fileHandle.close()
            
        case .failure(let error):
            if isAuthorizationCanceled(error) {
                throw BuildError.userCanceled
            } else if case .functionNotFound = error {
                throw BuildError.copyFailed(reason: "Authorization API not available")
            } else {
                throw BuildError.copyFailed(reason: error.localizedDescription)
            }
        }
    }
    
    private func isAuthorizationCanceled(_ error: Authorization.Error) -> Bool {
        switch error {
        case .copyRights(let status), .exec(let status):
            return status == errAuthorizationCanceled
        default:
            return false
        }
    }
    
    // MARK: - Private Methods - Build Script
    
    private func prepareAndCopyBuildScript(for type: RepositoryType) throws -> String {
        guard let resourcePath = Bundle.main.resourcePath else {
            throw BuildError.scriptNotFound(path: "Bundle resource path not found")
        }
        
        let scriptPath = (resourcePath as NSString).appendingPathComponent(type.buildScriptName)
        
        guard fileManager.fileExists(atPath: scriptPath) else {
            throw BuildError.scriptNotFound(path: scriptPath)
        }
        
        let destinationPath = type.localPath
        let copyCommand = "cp -R \"\(scriptPath)\" \"\(destinationPath)\""
        
        _ = try shellService.execute(copyCommand, outputTextView: nil)
        
        return (destinationPath as NSString).appendingPathComponent(type.buildScriptName)
    }
    
    private func executeBuildScript(at path: String, outputTextView: NSTextView?) throws {
        let buildCommand = "\(Constants.buildEnvironment); sh \"\(path)\""
        _ = try shellService.execute(buildCommand, outputTextView: outputTextView)
    }
}

// MARK: - BuildService + Validation

extension BuildService {
    
    func validateBuild(for type: RepositoryType) -> Bool {
        return fileManager.fileExists(atPath: type.binariesPath)
    }
    
    func cleanBinaries(for type: RepositoryType) throws {
        let binariesPath = type.binariesPath
        
        guard fileManager.fileExists(atPath: binariesPath) else { return }
        
        try fileManager.removeItem(atPath: binariesPath)
    }
}
