//
//  AudioAlertPlayer.swift
//  SensorSuite
//
//  Created by Timothy Zorn on 12/3/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import AVFAudio
import FactoryKit
import Foundation

protocol AudioPlayerProtocol {
    func playWrongPosition()
    func playTimeToTurn()
    func playWearableLowBattery()
}

enum AudioAlerts {
    case nonTargetPosition
    case timeToTurn
    case wearableLowBattery

    var textToSpeech: String {
        switch self {
        case .wearableLowBattery:
            return "Sensor is low on battery."
        case .timeToTurn:
            return "Time to turn your patient."
        case .nonTargetPosition:
            return "Non-Target position detected."
        }
    }
}

extension Container {
    var audioPlayer: Factory<AudioPlayerProtocol> {
        self { AudioAlertPlayer() }.cached
    }
}

final class AudioAlertPlayer: NSObject, ObservableObject, AudioPlayerProtocol {
    @Injected(\.speechSynthesizer) private var speechSynthesizer
    private lazy var chimesPlayer: AVAudioPlayer = {
        guard let chimeUrl = Bundle.main.url(forResource: "chime.mp3", withExtension: nil) else {
            fatalError("chime.mp3 not found")
        }
        guard let player = try? AVAudioPlayer(contentsOf: chimeUrl) else {
            fatalError("AVAudioPlayer failed to initialize with contents of: \(chimeUrl)")
        }
        player.delegate = self
        player.volume = 0.8
        player.numberOfLoops = 2
        return player
    }()
    @Published private var alertPlayerQueue: [AudioAlerts] = []

    func playWrongPosition() {
        if alertPlayerQueue.isEmpty {
            alertPlayerQueue.append(.nonTargetPosition)
            playChimes()
        }
    }

    func playTimeToTurn() {
        if alertPlayerQueue.isEmpty {
            alertPlayerQueue.append(.timeToTurn)
            playChimes()
        }
    }

    func playWearableLowBattery() {
        if alertPlayerQueue.isEmpty {
            alertPlayerQueue.append(.wearableLowBattery)
            playChimes()
        }
    }
}

private extension AudioAlertPlayer {
    func playOnce(_ alert: AudioAlerts) {
        speechSynthesizer.speak(alert.textToSpeech, delay: 0)
    }

    func playChimes() {
        chimesPlayer.play()
        // Strongly capture `self` so the instance is retained until 7 seconds has passed
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [self] in
            chimesPlayer.stop()
        }
    }
}

// MARK: - AVAudioPlayerDelegate Conformance
extension AudioAlertPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(
        _ finishedPlayer: AVAudioPlayer,
        successfully flag: Bool
    ) {
        if finishedPlayer.url?.pathComponents.last == "chime.mp3" {
            guard let currentAlert = alertPlayerQueue.popLast() else { return }
            playOnce(currentAlert)
        }
    }
}
