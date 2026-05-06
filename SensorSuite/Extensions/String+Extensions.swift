//
//  String+Extensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 8/26/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

extension String {
    static func randAlphanumeric(length: Int = 10) -> String {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        var randomString = ""

        for _ in 0 ..< length {
            let rand = UInt32.random(in: 0..<len)
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

    var double: Double {
        return Double(self) ?? 0.0
    }
    
    /// Inserts a single space after the first contiguous run of digits in the string.
    /// Examples: "5min" -> "5 min", "as150as" -> "as150 as". If the string ends with digits or has no digits, returns self.
    func insertSpaceAfterDigits() -> String {
        guard !isEmpty else { return self }
        var firstIndexOfDigits: Int?
        var lastIndexOfDigits: Int = 0
        for (index, char) in Array(self).enumerated() where char.isWholeNumber {
            if firstIndexOfDigits == nil {
                firstIndexOfDigits = index
            }
            lastIndexOfDigits = index
        }
        guard let firstIndexOfDigits else { return self }
        let lastIndex = max(firstIndexOfDigits, lastIndexOfDigits)
        guard let digitEndIndex = self.index(startIndex, offsetBy: lastIndex, limitedBy: endIndex) else {
            return self
        }
        let nextIndexAfterDigits = self.index(digitEndIndex, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        if nextIndexAfterDigits == endIndex { return self }
        guard !self[nextIndexAfterDigits].isWhitespace else {
            return self
        }
        return String(self[...digitEndIndex]) + " " + String(self[nextIndexAfterDigits...])
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
