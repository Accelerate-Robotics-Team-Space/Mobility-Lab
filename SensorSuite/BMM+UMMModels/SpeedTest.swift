//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
class SpeedTest: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    typealias SpeedTestCompletionHandler = (_ megabytesPerSecond: Double?, _ error: Error?) -> Void

    private let urlString =
    "https://assets-global.website-files.com/62de64bf66ff0fa853820aa7/631206d0f4eb4a030f642de0_technology-cover-horizontal-v2%20(1).jpg"

    var speedTestCompletionBlock: SpeedTestCompletionHandler?

    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!

    private let config: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = 5.0
        return configuration
    }()
    private lazy var session: URLSession = {
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    private let speedTestQueue = DispatchQueue(label: "SpeedTestQueue", qos: .default)

    func checkForSpeed() {
//        testDownloadSpeed() { speed, error in
//			logger.info("Download Speed: \(speed != nil ? String(speed!) : "NA")")
//			logger.info("Speed Test Error: \(error?.localizedDescription ?? "NA")")
//        }
    }

    func testDownloadSpeed(withCompletionBlock: @escaping SpeedTestCompletionHandler) {
//        guard let url = URL(string: urlString) else { return }
//
//        startTime = CFAbsoluteTimeGetCurrent()
//        stopTime = startTime
//        bytesReceived = 0
//
//        speedTestCompletionBlock = withCompletionBlock
//        speedTestQueue.async {
//            Task {
//                await self.session.reset()
//                self.session.dataTask(with: url).resume()
//            }
//        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if bytesReceived == 0 {
            startTime = CFAbsoluteTimeGetCurrent()
        }
        bytesReceived! += data.count
        stopTime = CFAbsoluteTimeGetCurrent()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let elapsed = stopTime - startTime
        if let aTempError = error as NSError?, aTempError.domain != NSURLErrorDomain && aTempError.code != NSURLErrorTimedOut && elapsed == 0 {
            speedTestCompletionBlock?(nil, error)
            speedTestQueue.async {
                Task {
                    await session.reset()
                }
            }
            return
        }

        let downloadSpeed = (Double(bytesReceived) / elapsed / 1024.0 / 1024.0) * 8
        let result = elapsed != 0 ? downloadSpeed : 0
        speedTestCompletionBlock?(result, nil)
        speedTestQueue.async {
            Task {
                await session.reset()
            }
        }
    }
}
