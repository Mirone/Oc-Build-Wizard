//
//  LogService.swift
//  OC Build Wizard
//
//  Copyright (C) 2024 - 2026 Mirone. All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

protocol LogServiceProtocol {
    typealias LogLevel = LogService.LogLevel

    func log(message: String)
    func log(message: String, level: LogLevel)
}

final class LogService: LogServiceProtocol {
    // MARK: - Properties
    
    private let logDirectory: String
    private let dateFormatter: DateFormatter
    private let fileManager: FileManager
    
    // MARK: - Initialization
    
    init(logDirectory: String = "/tmp", fileManager: FileManager = .default) {
        self.logDirectory = logDirectory
        self.fileManager = fileManager
        
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "pt_BR")
    }
    
    // MARK: - Public Methods
    
    func log(message: String) {
        let dateString = dateFormatter.string(from: Date())
        let logFilePath = buildLogFilePath(from: dateString)
        
        ensureLogFileExists(at: logFilePath)
        writeToLog(message: message, timestamp: dateString, filePath: logFilePath)
    }

    func log(message: String, level: LogLevel) {
        log(message: "[\(level.rawValue)] \(message)")
    }
    
    // MARK: - Private Methods
    
    private func buildLogFilePath(from dateString: String) -> String {
        let logFileName = "OC Build Wizard-\(dateString.prefix(10)).log"
        return "\(logDirectory)/\(logFileName)"
    }
    
    private func ensureLogFileExists(at path: String) {
        guard !fileManager.fileExists(atPath: path) else { return }
        fileManager.createFile(atPath: path, contents: nil, attributes: nil)
    }
    
    private func writeToLog(message: String, timestamp: String, filePath: String) {
        guard let fileHandle = FileHandle(forWritingAtPath: filePath) else {
            print("Failed to open log file at: \(filePath)")
            return
        }
        
        defer {
            fileHandle.synchronizeFile()
            fileHandle.closeFile()
        }
        
        fileHandle.seekToEndOfFile()
        
        let logMessage = "\(timestamp) - \(message)\n"
        guard let data = logMessage.data(using: .utf8) else {
            print("Failed to encode log message")
            return
        }
        
        fileHandle.write(data)
    }
}

// MARK: - LogService + Convenience

extension LogService {
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case success = "SUCCESS"
    }
}
