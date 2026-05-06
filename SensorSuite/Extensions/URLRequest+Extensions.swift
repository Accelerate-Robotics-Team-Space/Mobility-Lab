//
//  URLRequest+Extensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 10/9/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
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

        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }

        return command.joined(separator: " \\\n\t")
    }

    func bodyJSON() -> NSString? {
        if let data = self.httpBody {
            return data.prettyJSON() ?? NSString(data: data, encoding: NSUTF8StringEncoding)
        }
        return nil
    }

    func summary() -> NSString {
        NSString(
            format: "Request: %@ %@ %@",
            (httpMethod != nil ? "'\(httpMethod!)'" : ""),
            (url?.absoluteString ?? ""),
            (bodyJSON() ?? NSString(string: ""))
        )
    }

    var endpointSummary: NSString {
        NSString(
            format: "Request: %@ %@",
            (httpMethod != nil ? "'\(httpMethod!)'" : ""),
            (url?.absoluteString ?? "")
        )
    }
}
