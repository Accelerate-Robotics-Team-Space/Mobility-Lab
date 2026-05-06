//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockFileService: FileServiceProtocol, @unchecked Sendable {
    var deleteHandler: ((URL) throws -> Void)?
    var urlForHandler: ((DirectorySearchPath, SearchPathMask) throws -> URL)?
    var createDirectoryHandler: ((URL) throws -> Void)?
    var saveFileHandler: ((Data, String, String?, DirectorySearchPath, SearchPathMask) throws -> Void)?
    var fileDataHandler: ((String, String?, DirectorySearchPath, SearchPathMask) throws -> Data?)?
    var fileExistsHandler: ((String, String?, DirectorySearchPath, SearchPathMask) throws -> Bool)?

    func fileExists(_ filename: String, folder: String?, for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws -> Bool {
        guard let fileExistsHandler else {
            fatalError("fileExistsHandler must be set")
        }
        return try fileExistsHandler(filename, folder, searchPath, mask)
    }
    
    func file(_ filename: String, folder: String?, for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws -> Data? {
        guard let fileDataHandler else {
            fatalError("fileDataHandler must be set")
        }
        return try fileDataHandler(filename, folder, searchPath, mask)
    }
    
    func save(file data: Data, to filename: String, folder: String?, for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws {
        guard let saveFileHandler else {
            fatalError("saveFileHandler must be set")
        }
        try saveFileHandler(data, filename, folder, searchPath, mask)
    }
    
    func createDirectory(at url: URL) throws {
        guard let createDirectoryHandler else {
            fatalError("createDirectoryHandler not set")
        }
        try createDirectoryHandler(url)
    }
    
    func url(for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws -> URL {
        guard let urlForHandler else {
            fatalError("urlForHandler not set")
        }
        return try urlForHandler(searchPath, mask)
    }
    
    func delete(_ url: URL) throws {
        guard let deleteHandler else {
            fatalError("deleteHandler not set")
        }
        try deleteHandler(url)
    }
}

final class NullFileService: FileServiceProtocol {
    func fileExists(_ filename: String, folder: String?, for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws -> Bool {
        fatalError("Null Service Should Not Be Used")
    }

    func file(_ filename: String, folder: String?, for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws -> Data? {
        fatalError("Null Service Should Not Be Used")
    }

    func save(file data: Data, to filename: String, folder: String?, for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws {
        fatalError("Null Service Should Not Be Used")
    }

    func createDirectory(at url: URL) throws {
        fatalError("Null Service Should Not Be Used")
    }

    func url(for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws -> URL {
        fatalError("Null Service Should Not Be Used")
    }

    func delete(_ url: URL) throws {
        fatalError("Null Service Should Not Be Used")
    }
}
