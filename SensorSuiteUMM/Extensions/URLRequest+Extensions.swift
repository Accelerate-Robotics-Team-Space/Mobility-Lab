//
//  URLRequest+Extensions.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/21/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

extension URLRequest {
    var curl: String {
            guard let url = url else { return "" }
            var baseCommand = #"curl "\#(url.absoluteString)""#

            if httpMethod == "HEAD" {
                baseCommand += " --head"
            }

            var command = [baseCommand]

            if let method = httpMethod, method != "GET" && method != "HEAD" {
                command.append("-X \(method)")
            }

            if let headers = allHTTPHeaderFields {
                for (key, value) in headers where key != "Cookie" {
                    command.append("-H '\(key): \(value)'")
                }
            }

        if let data = httpBody {
                command.append("-d '\(String(decoding: data, as: UTF8.self))'")
            }

            return command.joined(separator: " \\\n\t")
        }
}
