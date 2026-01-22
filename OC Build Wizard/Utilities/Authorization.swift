//
//  Authorization.swift
//  OC Build Wizard
//
//  Copyright (C) 2024 - 2026 Mirone. All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import Security

// REF:
// https://github.com/sveinbjornt/STPrivilegedTask/blob/master/STPrivilegedTask.m
// https://github.com/x13a/authorization-swift/blob/master/Sources/Authorization/Authorization.swift


public struct Authorization {
    public enum Error: Swift.Error {
        case create(OSStatus)
        case copyRights(OSStatus)
        case exec(OSStatus)
        case functionNotFound
    }

    public enum Command {
        case string(String)
        case pathArgs(path: String, args: [String])
    }
}

extension Authorization.Command: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

public extension Authorization {
    
    static func executeWithPrivileges(_ command: Command) -> Result<FileHandle, Error> {
       
        let (path, args): (String, [String]) = {
            switch command {
            case .string(let cmd):
                let components = cmd.split(separator: " ").map(String.init)
                return (components.first ?? "", Array(components.dropFirst()))
            case .pathArgs(let path, let args):
                return (path, args)
            }
        }()

        guard !path.isEmpty else {
            return .failure(.exec(-1))
        }

        guard let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "AuthorizationExecuteWithPrivileges") else {
            return .failure(.functionNotFound)
        }

        typealias AuthExecFunc = @convention(c) (
            AuthorizationRef,
            UnsafePointer<CChar>,
            AuthorizationFlags,
            UnsafePointer<UnsafePointer<CChar>?>?,
            UnsafeMutablePointer<UnsafeMutablePointer<FILE>?>?
        ) -> OSStatus

        let authExecuteWithPrivs = unsafeBitCast(sym, to: AuthExecFunc.self)

        var authorizationRef: AuthorizationRef?
        let statusCreate = AuthorizationCreate(nil, nil, [], &authorizationRef)
        guard statusCreate == errAuthorizationSuccess, let authRef = authorizationRef else {
            return .failure(.create(statusCreate))
        }

        defer { AuthorizationFree(authRef, [.destroyRights]) }

        let argsCStrings = args.map { strdup($0) }
        defer { for ptr in argsCStrings { free(ptr) } }

        var argv: [UnsafePointer<CChar>?] = argsCStrings.map { UnsafePointer($0) }
        argv.append(nil)

        return path.withCString { pathCString in
            return kAuthorizationRightExecute.withCString { execRight in
                var authItem = AuthorizationItem(
                    name: execRight,
                    valueLength: strlen(pathCString),
                    value: UnsafeMutableRawPointer(mutating: pathCString),
                    flags: 0
                )
                return withUnsafeMutablePointer(to: &authItem) { authItemPtr in
                    var rights = AuthorizationRights(count: 1, items: authItemPtr)
                    let flags: AuthorizationFlags = [.interactionAllowed, .preAuthorize, .extendRights]
                    let statusRights = AuthorizationCopyRights(authRef, &rights, nil, flags, nil)
                    guard statusRights == errAuthorizationSuccess else {
                        return .failure(.copyRights(statusRights))
                    }
                    var commPipe: UnsafeMutablePointer<FILE>? = nil
                    let statusExec = authExecuteWithPrivs(authRef, pathCString, [], &argv, &commPipe)
                    guard statusExec == errAuthorizationSuccess, let pipe = commPipe else {
                        return .failure(.exec(statusExec))
                    }
                    let fileHandle = FileHandle(fileDescriptor: fileno(pipe), closeOnDealloc: true)
                    return .success(fileHandle)
                } 
            }
        }
    }
}
