//
// AppDelegate.swift
// OC Build Wizard
//
// Copyright (C) 2024 - 2025 Mirone. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet var window: NSWindow!
    @IBOutlet var labelProgress: NSTextField!
    @IBOutlet var theWindow: NSWindow!
    @IBOutlet var indeterminateprogress: NSProgressIndicator!
    @IBOutlet var myTextView: NSTextView!
    @IBOutlet var btnAcidanthera: NSButton!
    @IBOutlet var btnBtwise: NSButton!
    
    // MARK: - Properties
    
    private var viewModel: MainViewModel!
    
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupViewModel()
        viewModel.checkInitialState()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ aNotification: NSApplication) -> Bool {
        return true
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Setup
    
    private func setupViewModel() {
        let shellService = ShellService()
        let repositoryService = RepositoryService(shellService: shellService)
        let buildService = BuildService(shellService: shellService)
        
        viewModel = MainViewModel(
            repositoryService: repositoryService,
            buildService: buildService,
            shellService: shellService
        )
        
        bindViewModel()
    }
    
    /// Conecta os callbacks do ViewModel à interface
    private func bindViewModel() {
        viewModel.onStatusUpdate = { [weak self] status in
            self?.labelProgress.stringValue = status
        }
        
        viewModel.onProgressUpdate = { [weak self] isAnimating in
            if isAnimating {
                self?.indeterminateprogress.startAnimation(nil)
            } else {
                self?.indeterminateprogress.stopAnimation(nil)
            }
        }
        
        viewModel.onAlert = { [weak self] title, message, style in
            self?.showAlert(title: title, message: message, alertStyle: style)
        }
        
        viewModel.onConfirmationAlert = { title, message, completion in
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.addButton(withTitle: "YES")
            alert.addButton(withTitle: "NO")
            alert.alertStyle = .informational
            
            let response = alert.runModal()
            completion(response == .alertFirstButtonReturn)
        }
        
        viewModel.onButtonStateChange = { [weak self] isEnabled in
            self?.btnAcidanthera.isEnabled = isEnabled
            self?.btnBtwise.isEnabled = isEnabled
        }
        
        viewModel.onError = { [weak self] error in
            self?.showAlert(title: "Error", message: error.localizedDescription, alertStyle: .critical)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func buildOpenCore(_ sender: NSButton) {
        let repositoryType: RepositoryType = sender.tag == 1 ? .acidanthera : .btwise
        viewModel.buildOpenCore(repositoryType: repositoryType, outputTextView: myTextView)
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String, alertStyle: NSAlert.Style = .informational) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = alertStyle
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
