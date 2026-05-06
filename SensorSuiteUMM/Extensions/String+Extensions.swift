//
//  String+Extensions.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

extension String {
    static func randAlphanumeric(length: Int = 10) -> String {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(len) // swiftlint:disable:this legacy_random
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
    }
    
    func formattedId(using char: Character = "-") -> String {
        let midIndex = self.count / 2
        var newStr = self
        var insertIndex = self.index(self.startIndex, offsetBy: midIndex - 1)
        
        newStr.insert(char, at: insertIndex)
        insertIndex = self.index(self.startIndex, offsetBy: midIndex + 2)
        newStr.insert(char, at: insertIndex)
        
        return newStr.uppercased()
    }
    
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch {
			logger.error("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func toALTSex() -> ALTSex {
        if self == "M" {
            return ALTSex(rawValue: self)!
        } else if self == "F" {
            return ALTSex(rawValue: self)!
        } else if self == "U" {
            return ALTSex(rawValue: self)!
        } else if self == "N" {
            return ALTSex(rawValue: self)!
        } else {
            return ALTSex(rawValue: "N")!
        }
    }
}

// MARK: - Serializable
extension String: Serializable {
    func toData() -> Data {
        Data(self.utf8)
    }
    
    init?(serialize data: Data) {
        self = String(decoding: data, as: UTF8.self)
    }
}
