//
//  AudioAlertHandler.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 9/19/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol AudioAlertHandlerProtocol {
    func stopSpeaking()
}

extension Container {
    var audioAlertHandler: Factory<AudioAlertHandlerProtocol> {
        self { AudioAlertHandler() }.cached
    }
}

extension Notification.Name {
    static let bmmAlertNote = Notification.Name("bmm-alert")
}

class AudioAlertHandler: AudioAlertHandlerProtocol {
    @Injected(\.speechSynthesizer)
    private var speechSynthesizer

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(bmmAlertHandler), name: .bmmAlertNote, object: nil)
    }

    @objc
    private func bmmAlertHandler(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let alertModel = userInfo["model"] as? AlertModel else {
            logger.warn("Could not find Alert Info in notification")
            return
        }

        // Check if Filter by Unit enabled, ignore filtered out BMM's alerts if so
        if let selectedUnit = UserDefaults.standard.selectedFilterUnitName,
           !selectedUnit.isEmpty,
           selectedUnit != alertModel.unit {
            logger.warn("Alert is not fired because bmm is filtered out")
            return
        }

        speechSynthesizer.speak(alertModel.textToSpeech, delay: 1)
    }

    func stopSpeaking() {
        speechSynthesizer.stopSpeaking()
    }
}
