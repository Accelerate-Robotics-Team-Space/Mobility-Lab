//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation

struct AppVersion: Hashable, Sendable {
    let major: Int
    let minor: Int
    let patch: Int

    // No-one seems to know what this means.
    // Apparently, once-upon-a-time it used to be used for the build number?
    let atlasExtra: Int?

    /// Defaults to `1.0.x.0`
    /// Atlas builds only increment the patch version.
    init(major: Int = 1, minor: Int = 0, _ patch: Int, atlasExtra: Int? = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.atlasExtra = atlasExtra
    }

    var rawString: String {
        if let atlasExtra {
            return "\(major).\(minor).\(patch).\(atlasExtra)"
        } else {
            return "\(major).\(minor).\(patch)"
        }
    }
}

extension AppVersion {
    init?(_ version: String) {
        let parts = version.split(separator: ".").compactMap { Int($0) }

        guard [3, 4].contains(parts.count) else { return nil }
        self.major = parts[0]
        self.minor = parts[1]
        self.patch = parts[2]
        if parts.count == 4 {
            self.atlasExtra = parts[3]
        } else {
            self.atlasExtra = nil
        }
    }
}

extension AppVersion: Comparable {
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        } else if lhs.patch != rhs.patch {
            return lhs.patch < rhs.patch
        } else if let lhsAtlas = lhs.atlasExtra, let rhsAtlas = rhs.atlasExtra, lhsAtlas != rhsAtlas {
            return lhsAtlas < rhsAtlas
        } else {
            // all are equal, or, there is a nil & not-nil `atlasExtra` we cannot compare
            return false
        }
    }
}
