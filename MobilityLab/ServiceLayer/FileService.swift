//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol FileServiceProtocol: AnyObject & Sendable {
    func createDirectory(at url: URL) throws
    func url(for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws -> URL
    func delete(_ url: URL) throws

    func save(file data: Data, to filename: String, folder: String?, for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws
    func save(file data: Data, to filename: String, folder: String?, for searchPath: DirectorySearchPath) throws
    func save(file data: Data, to filename: String, folder: String?, in mask: SearchPathMask) throws
    func save(file data: Data, to filename: String, folder: String?) throws

    func file(_ filename: String, folder: String?, for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws -> Data?
    func file(_ filename: String, folder: String?, for searchPath: DirectorySearchPath) throws -> Data?
    func file(_ filename: String, folder: String?, in mask: SearchPathMask) throws -> Data?
    func file(_ filename: String, folder: String?) throws -> Data?

    func fileExists(_ filename: String, folder: String?, for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws -> Bool
    func fileExists(_ filename: String, folder: String?) throws -> Bool
}

extension FileServiceProtocol {
    func file(_ filename: String, folder: String?, for searchPath: DirectorySearchPath) throws -> Data? {
        try file(filename, folder: folder, for: searchPath, in: .userDomain)
    }

    func file(_ filename: String, folder: String?, in mask: SearchPathMask) throws -> Data? {
        try file(filename, folder: folder, for: .documents, in: mask)
    }

    func file(_ filename: String, folder: String?) throws -> Data? {
        try file(filename, folder: folder, for: .documents, in: .userDomain)
    }

    func save(file data: Data, to filename: String, folder: String?, for searchPath: DirectorySearchPath) throws {
        try save(file: data, to: filename, folder: folder, for: searchPath, in: .userDomain)
    }

    func save(file data: Data, to filename: String, folder: String?, in mask: SearchPathMask) throws {
        try save(file: data, to: filename, folder: folder, for: .documents, in: mask)
    }

    func save(file data: Data, to filename: String, folder: String?) throws {
        try save(file: data, to: filename, folder: folder, for: .documents, in: .userDomain)
    }

    func fileExists(_ filename: String, folder: String?) throws -> Bool {
        try fileExists(filename, folder: folder, for: .documents, in: .userDomain)
    }
}

enum DirectorySearchPath {
    case caches
    case documents
    case library
    case applicationSupport
}

struct SearchPathMask: OptionSet {

    typealias RawValue = UInt8

    let rawValue: RawValue

    static let userDomain = SearchPathMask(rawValue: 1 << 0)
    static let localDomain = SearchPathMask(rawValue: 1 << 1)
    static let networkDomain = SearchPathMask(rawValue: 1 << 2)
    static let systemDomain = SearchPathMask(rawValue: 1 << 3)
    static let allDomains: SearchPathMask = [.userDomain, .localDomain, .networkDomain, .systemDomain]
}

extension Container {
    var fileService: Factory<FileServiceProtocol> {
        self { FileService() }.cached
    }
}

final class FileService: FileServiceProtocol, @unchecked Sendable {
    private let fileManager: FileManager

    init(_ fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func url(for searchPath: DirectorySearchPath, in mask: SearchPathMask) throws -> URL {
        try fileManager.url(
            for: .init(searchPath),
            in: .init(mask),
            appropriateFor: nil,
            create: true
        )
    }

    func file(at url: URL) -> Data? {
        let path = url.path(percentEncoded: false)
        return fileManager.contents(atPath: path)
    }

    func checkIsDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false

        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            return isDirectory.boolValue
        }
        return false
    }

    func createFile() {
        let filePath = "/User/Documents/user_info.txt"

        if !fileManager.fileExists(atPath: filePath) {
            fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
            // success
        }
    }

    func deleteFile() {
        let filePath = "user_info.txt"

        do {
            try fileManager.removeItem(atPath: filePath)
            // deleted
        } catch {
            // error
        }
    }

    func save(
        file data: Data,
        to filename: String,
        folder: String?,
        for searchPath: DirectorySearchPath,
        in mask: SearchPathMask
    ) throws {
        let rootFolderURL = try fileManager.url(
            for: .init(searchPath),
            in: .init(mask),
            appropriateFor: nil,
            create: false
        )

        let nestedFolderURL: URL
        if let folder {
            nestedFolderURL = rootFolderURL.appendingPathComponent(folder)
        } else {
            nestedFolderURL = rootFolderURL
        }

        do {
            try fileManager.createDirectory(
                at: nestedFolderURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
        } catch CocoaError.fileWriteFileExists {
            // Folder already existed
        } catch {
            throw error
        }

        let fileURL = nestedFolderURL.appendingPathComponent(filename)
        try data.write(to: fileURL, options: .atomic)
    }

    func file(
        _ filename: String,
        folder: String?,
        for searchPath: DirectorySearchPath,
        in mask: SearchPathMask
    ) throws -> Data? {
        let rootFolderURL = try fileManager.url(
            for: .init(searchPath),
            in: .init(mask),
            appropriateFor: nil,
            create: false
        )

        let nestedFolderURL: URL
        if let folder {
            nestedFolderURL = rootFolderURL.appendingPathComponent(folder)
        } else {
            nestedFolderURL = rootFolderURL
        }

        let fileURL = nestedFolderURL.appendingPathComponent(filename)

        let data = try Data(contentsOf: fileURL)
        return data
    }

    func fileExists(
        _ filename: String,
        folder: String?,
        for searchPath: DirectorySearchPath = .documents,
        in mask: SearchPathMask = .userDomain
    ) throws -> Bool {
        let rootFolderURL = try fileManager.url(
            for: .init(searchPath),
            in: .init(mask),
            appropriateFor: nil,
            create: false
        )

        let nestedFolderURL: URL
        if let folder {
            nestedFolderURL = rootFolderURL.appendingPathComponent(folder)
        } else {
            nestedFolderURL = rootFolderURL
        }

        let fileURL = nestedFolderURL.appendingPathComponent(filename)

        let exists = fileManager.fileExists(atPath: fileURL.relativePath)
        return exists
    }

    func delete(_ url: URL) throws {
        try fileManager.removeItem(at: url)
    }
}

extension FileManager.SearchPathDirectory {

    init(_ searchPath: DirectorySearchPath) {
        switch searchPath {
        case .caches:
            self = .cachesDirectory
        case .documents:
            self = .documentDirectory
        case .library:
            self = .libraryDirectory
        case .applicationSupport:
            self = .applicationSupportDirectory
        }
    }

}

extension FileManager.SearchPathDomainMask {

    init(_ searchPathMask: SearchPathMask) {
        if searchPathMask == .localDomain {
            self = .localDomainMask
        } else if searchPathMask == .networkDomain {
            self = .networkDomainMask
        } else if searchPathMask == .systemDomain {
            self = .systemDomainMask
        } else if searchPathMask == .userDomain {
            self = .userDomainMask
        } else if searchPathMask == .allDomains {
            self = .allDomainsMask
        } else {
            fatalError("Unsupported Search Path Mask")
        }
    }

}
