//
//  SpeechSynthesizer.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 12/28/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import AVFoundation
import FactoryKit
import Foundation

protocol SpeechSynthesizerProtocol {
    func speak(_ text: String, delay: TimeInterval)
    func stopSpeaking()
}

extension Container {
    var speechSynthesizer: Factory<SpeechSynthesizerProtocol> {
        self { SpeechSynthesizer() }.cached
    }
}

class SpeechSynthesizer: NSObject, SpeechSynthesizerProtocol {
    private var synthesizer = AVSpeechSynthesizer()
	private static let preferredVoiceIdentifier = "com.apple.voice.enhanced.en-US.Samantha"
	private var utteranceQueue: [AVSpeechUtterance] = []

	override init() {
		super.init()
		synthesizer.delegate = self
	}

    func speak(_ text: String, delay: TimeInterval = 0) {
        let utterance = AVSpeechUtterance(string: text)
        if let voice = AVSpeechSynthesisVoice(identifier: Self.preferredVoiceIdentifier) {
            utterance.voice = voice
        }
        utterance.preUtteranceDelay = delay
        speak(utterance)
    }

    func speak(_ utterance: AVSpeechUtterance) {
		if !synthesizer.isSpeaking {
			synthesizer.speak(utterance)
		} else {
			utteranceQueue.append(utterance)
		}
    }

    func stopSpeaking() {
		utteranceQueue = []
		guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
		synthesizer = AVSpeechSynthesizer()
    }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
		guard !utteranceQueue.isEmpty else { return }
		let nextUtterance = utteranceQueue.removeFirst()
		synthesizer.speak(nextUtterance)
	}
}
