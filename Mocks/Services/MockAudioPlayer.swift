//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_BMM

final class MockAudioPlayer: AudioPlayerProtocol {
    var playWrongPositionHandler: (() -> Void)?
    var playTimeToTurnHandler: (() -> Void)?
    var playWearableLowBatteryHandler: (() -> Void)?

    func playWrongPosition() {
        guard let playWrongPositionHandler else {
            fatalError("playWrongPositionHandler must be set")
        }
        playWrongPositionHandler()
    }
    
    func playTimeToTurn() {
        guard let playTimeToTurnHandler else {
            fatalError("playTimeToTurnHandler must be set")
        }
        playTimeToTurnHandler()
    }
    
    func playWearableLowBattery() {
        guard let playWearableLowBatteryHandler else {
            fatalError("playWearableLowBatteryHandler must be set")
        }
        playWearableLowBatteryHandler()
    }
}

final class NullAudioPlayer: AudioPlayerProtocol {
    func playWrongPosition() {
        fatalError("Null Service Should Not Be Used")
    }

    func playTimeToTurn() {
        fatalError("Null Service Should Not Be Used")
    }

    func playWearableLowBattery() {
        fatalError("Null Service Should Not Be Used")
    }
}
