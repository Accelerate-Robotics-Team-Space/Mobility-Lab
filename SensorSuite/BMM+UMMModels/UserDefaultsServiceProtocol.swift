//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

protocol UserDefaultsServiceProtocol: AnyObject {
    var lastCertificateRevocationListCheck: Date { get set }
    var baseStationGuid: String? { get set }
    var deviceGuid: String? { get set } // different for BMM & UMM
    var facilityId: String? { get set }
    var facilityName: String? { get set }
    var peerIdKey: Int { get set }
    var baseStationFromApple: String? { get set }
    var defaultingBaseStationFromApple: String { get }
    var host: String { get set }
    func reset()
    func incrementPeerIDKey() -> Int
    var lastRunVersion: AppVersion? { get set }
}
