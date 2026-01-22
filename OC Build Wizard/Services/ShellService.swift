//
//  ShellService.swift
//  OC Build Wizard
//
//  Copyright (C) 2024 - 2026 Mirone. All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import Foundation

protocol ShellServiceProtocol {
    func execute(_ command: String, outputTextView: NSTextView?) throws -> String
    func getOpenCoreVersion() throws -> String
}

final class ShellService: ShellServiceProtocol {
    // MARK: - Constants
    
    private enum Constants {
        static let shellPath = "/bin/zsh"
        static let openCoreVersionCommand = "nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}'"
        static let outputQueueLabel = "com.ocbuildwizard.shell.output"
    }
    
    // MARK: - Public Methods
    
    func execute(_ command: String, outputTextView: NSTextView?) throws -> String {
        let task = createTask(with: command)
        let pipe = Pipe()
        task.standardOutput = pipe
        
        var outputData = Data()
        let group = DispatchGroup()
        
        group.enter()
        
        executeTask(task, pipe: pipe, outputTextView: outputTextView) { data in
            outputData = data
            group.leave()
        }
        
        group.wait()
        
        try validateTaskExecution(task)
        
        return parseOutput(from: outputData)
    }
    
    func getOpenCoreVersion() throws -> String {
        return try execute(Constants.openCoreVersionCommand, outputTextView: nil)
    }
    
    // MARK: - Private Methods
    
    private func createTask(with command: String) -> Process {
        let task = Process()
        task.launchPath = Constants.shellPath
        task.arguments = ["-c", command]
        return task
    }
    
    private func executeTask(_ task: Process, pipe: Pipe, outputTextView: NSTextView?, completion: @escaping (Data) -> Void) {
        DispatchQueue.global().async {
            let capturedOutputData = UnsafeMutablePointer<Data>.allocate(capacity: 1)
            capturedOutputData.initialize(to: Data())
            defer {
                let dataToReturn = capturedOutputData.pointee
                capturedOutputData.deinitialize(count: 1)
                capturedOutputData.deallocate()
                completion(dataToReturn)
            }
            
            task.launch()
            
            pipe.fileHandleForReading.readabilityHandler = { [weak outputTextView] fileHandle in
                let data = fileHandle.availableData
                capturedOutputData.pointee.append(data)
                
                self.updateTextView(outputTextView, with: capturedOutputData.pointee)
            }
            
            task.waitUntilExit()
            // Stop readability handler to avoid further callbacks
            pipe.fileHandleForReading.readabilityHandler = nil
        }
    }
    
    private func updateTextView(_ textView: NSTextView?, with data: Data) {
        guard let textView = textView,
              let outputString = String(data: data, encoding: .utf8)
        else {
            return
        }
        
        DispatchQueue.main.async {
            textView.string = outputString
            textView.scrollToEndOfDocument(nil)
        }
    }
    
    private func validateTaskExecution(_ task: Process) throws {
        guard task.terminationStatus == 0 else {
            throw ShellError.executionFailed(status: task.terminationStatus)
        }
    }
    
    private func parseOutput(from data: Data) -> String {
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
    }
}

// MARK: - ShellError

enum ShellError: LocalizedError {
    case executionFailed(status: Int32)
    
    var errorDescription: String? {
        switch self {
        case .executionFailed(let status):
            return "Shell command failed with status code: \(status)"
        }
    }
}
