//
//  RepositoryService.swift
//  OC Build Wizard
//
//  Copyright (C) 2024 - 2026 Mirone. All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

enum RepositoryError: LocalizedError {
    case updateFailed(underlying: Error)
    case cloneFailed(underlying: Error)
    case repositoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .updateFailed(let error):
            return "Failed to update repository: \(error.localizedDescription)"
        case .cloneFailed(let error):
            return "Failed to clone repository: \(error.localizedDescription)"
        case .repositoryNotFound:
            return "Repository not found at expected location"
        }
    }
}

protocol RepositoryServiceProtocol {
    func checkAndCloneRepository(type: RepositoryType, completion: @escaping (Result<String, Error>) -> Void)
}

final class RepositoryService: RepositoryServiceProtocol {
    // MARK: - Properties
    
    private let shellService: ShellServiceProtocol
    private let fileManager: FileManager
    
    // MARK: - Initialization
    
    init(shellService: ShellServiceProtocol, fileManager: FileManager = .default) {
        self.shellService = shellService
        self.fileManager = fileManager
    }
    
    // MARK: - Public Methods
    
    func checkAndCloneRepository(type: RepositoryType, completion: @escaping (Result<String, Error>) -> Void) {
        if type.exists {
            updateRepository(type: type, completion: completion)
        } else {
            cloneRepository(type: type, completion: completion)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateRepository(type: RepositoryType, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let command = self.buildUpdateCommand(for: type)
                let output = try self.shellService.execute(command, outputTextView: nil)
                
                DispatchQueue.main.async {
                    completion(.success(output))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(RepositoryError.updateFailed(underlying: error)))
                }
            }
        }
    }
    
    private func cloneRepository(type: RepositoryType, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let command = self.buildCloneCommand(for: type)
                _ = try self.shellService.execute(command, outputTextView: nil)
                
                DispatchQueue.main.async {
                    completion(.success("Repository cloned successfully"))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(RepositoryError.cloneFailed(underlying: error)))
                }
            }
        }
    }
    
    private func buildUpdateCommand(for type: RepositoryType) -> String {
        "cd \(type.localPath); git pull origin master"
    }
    
    private func buildCloneCommand(for type: RepositoryType) -> String {
        let homeDirectory = NSHomeDirectory()
        return "cd \(homeDirectory); git clone \(type.url)"
    }
}

// MARK: - RepositoryService + Validation

extension RepositoryService {
    func validateRepository(type: RepositoryType) -> Bool {
        let gitPath = type.localURL.appendingPathComponent(".git").path
        return fileManager.fileExists(atPath: gitPath)
    }
}
