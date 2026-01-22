//
//  MainViewModel.swift
//  OC Build Wizard
//
//  Copyright (C) 2024 - 2026 Mirone. All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import Foundation

/// ViewModel principal que coordena toda a lógica da aplicação
final class MainViewModel {
    // MARK: - Properties
    
    private let networkService: NetworkServiceProtocol
    private let repositoryService: RepositoryServiceProtocol
    private let buildService: BuildServiceProtocol
    private let shellService: ShellServiceProtocol
    private let logService: LogServiceProtocol
    
    // MARK: - Observables (Callbacks para a View)
    
    var onStatusUpdate: ((String) -> Void)?
    
    var onProgressUpdate: ((Bool) -> Void)?
    
    var onAlert: ((String, String, NSAlert.Style) -> Void)?
    
    var onConfirmationAlert: ((String, String, @escaping (Bool) -> Void) -> Void)?
    
    var onBuildComplete: ((String, TimeInterval) -> Void)?
    
    var onError: ((Error) -> Void)?
    
    var onButtonStateChange: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    init(networkService: NetworkServiceProtocol = NetworkService(),
         repositoryService: RepositoryServiceProtocol,
         buildService: BuildServiceProtocol,
         shellService: ShellServiceProtocol = ShellService(),
         logService: LogServiceProtocol = LogService())
    {
        self.networkService = networkService
        self.repositoryService = repositoryService
        self.buildService = buildService
        self.shellService = shellService
        self.logService = logService
    }
    
    // MARK: - Public Methods
    
    func checkInitialState() {
        updateOpenCoreVersion()
        
        guard networkService.isConnectedToNetwork() else {
            handleNoInternetConnection()
            return
        }
    }

    func updateOpenCoreVersion() {
        do {
            let version = try shellService.getOpenCoreVersion()
            
            if version.isEmpty {
                onStatusUpdate?("OpenCore is not installed!")
                logService.log(message: "OpenCore not found!", level: .warning)
            } else {
                onStatusUpdate?("OpenCore Version: \(version)")
                logService.log(message: "OpenCore version detected: \(version)", level: .info)
            }
        } catch {
            onStatusUpdate?("")
            logService.log(message: "Error getting OpenCore version: \(error)", level: .error)
        }
    }
    
    func buildOpenCore(repositoryType: RepositoryType, outputTextView: NSTextView?) {
        logService.log(message: "Starting build process for \(repositoryType.name)", level: .info)
        
        onProgressUpdate?(true)
        onButtonStateChange?(false)
        onStatusUpdate?("Checking repository...")
        
        repositoryService.checkAndCloneRepository(type: repositoryType) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleRepositorySuccess(message: message, repositoryType: repositoryType, outputTextView: outputTextView)
                
            case .failure(let error):
                self.handleRepositoryError(error)
            }
        }
    }
    
    // MARK: - Private Methods - Repository Handling
    
    private func handleRepositorySuccess(message: String, repositoryType: RepositoryType, outputTextView: NSTextView?) {
        logService.log(message: "Repository ready: \(message)", level: .success)
        
        if message.contains("Already up to date") || message.contains("Updating") {
            onStatusUpdate?("Updating your local repository...")
            onAlert?("OC Build Wizard", message, .informational)
        }
        
        onConfirmationAlert?("Do you want to build OpenCore now?",
                             "This will compile OpenCore and may take some time. Are you sure you want to proceed?")
        { [weak self] confirmed in
            guard let self = self else { return }
            
            if confirmed {
                self.executeBuild(repositoryType: repositoryType, outputTextView: outputTextView)
            } else {
                self.logService.log(message: "Build canceled by user", level: .info)
                self.resetUI()
            }
        }
    }
    
    private func handleRepositoryError(_ error: Error) {
        logService.log(message: "Repository error: \(error.localizedDescription)", level: .error)
        
        onProgressUpdate?(false)
        onAlert?("Repository Error", "Failed to update/clone repository: \(error.localizedDescription)", .critical)
        resetUI()
    }
    
    // MARK: - Private Methods - Build Execution
    
    private func executeBuild(repositoryType: RepositoryType, outputTextView: NSTextView?) {
        do {
            logService.log(message: "Checking required build tools", level: .info)
            try buildService.checkRequiredTools()
            
            let config = BuildConfiguration(repositoryType: repositoryType)
            onStatusUpdate?("Build in progress, please wait...")
            
            logService.log(message: "Starting compilation...", level: .info)
            
            buildService.buildOpenCore(config: config, outputTextView: outputTextView) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let binFolder):
                    self.handleBuildSuccess(config: config, binFolder: binFolder)
                    
                case .failure(let error):
                    self.handleBuildError(error)
                }
            }
        } catch BuildError.userCanceled {
            handleBuildCancellation()
        } catch {
            logService.log(message: "Build preparation failed: \(error)", level: .error)
            onError?(error)
            resetUI()
        }
    }
    
    private func handleBuildSuccess(config: BuildConfiguration, binFolder: String) {
        updateOpenCoreVersion()
        onProgressUpdate?(false)
        
        let timeString = config.formattedElapsedTime
        
        logService.log(message: "Build completed successfully in \(timeString)", level: .success)
        
        onBuildComplete?(binFolder, config.elapsedTime)
        onAlert?("OC Build Wizard", "Build successfully in \(timeString)", .informational)
        onButtonStateChange?(true)
        
        openBinariesFolder(binFolder)
    }
    
    private func handleBuildError(_ error: Error) {
        logService.log(message: "Build failed: \(error.localizedDescription)", level: .error)
        
        onProgressUpdate?(false)
        onAlert?("Build Error", "Failed to build OpenCore: \(error.localizedDescription)", .critical)
        resetUI()
    }
    
    private func handleBuildCancellation() {
        logService.log(message: "File copy canceled by user", level: .warning)
        
        onAlert?("File Copy Canceled!",
                 "It is necessary to grant permission to copy the files: Nasm, Mtoc, Ndisam and Iasl.\n\nOtherwise it will not be possible to build OpenCore.",
                 .warning)
        resetUI()
    }
    
    // MARK: - Private Methods - UI Control
    
    private func resetUI() {
        onProgressUpdate?(false)
        onButtonStateChange?(true)
        updateOpenCoreVersion()
    }
    
    private func handleNoInternetConnection() {
        logService.log(message: "No internet connection detected", level: .error)
        
        onButtonStateChange?(false)
        onAlert?("Connection Error!", "Check your internet connection and try again", .critical)
    }
    
    private func openBinariesFolder(_ path: String) {
        do {
            _ = try shellService.execute("open \(path)", outputTextView: nil)
        } catch {
            logService.log(message: "Failed to open binaries folder: \(error)", level: .warning)
        }
    }
}
