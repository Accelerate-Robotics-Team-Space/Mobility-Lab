//
//  DeviceRegistrationLandingDriver.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/18/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import AVFoundation
import FactoryKit
import Foundation
import SwiftUI

class DeviceRegistrationLandingDriver: ObservableObject {
    @Injected(\.securityService) 
    private var securityService
    @Published var isDevMode = false
    @Published var isRegistered = Container.shared.securityService().isDeviceRegistered
    @Published var showAlert = false
    @Published var showAdminPanel = false
    @Published var modal: ActiveModal?
    @Published var currentScreen: CurrentScreen = Container.shared.securityService().isDeviceRegistered ? .dashboard : .landing
    @Published var bmms: [BMMStruct] = []
    
    private(set) var actionSheetBtns: [String: (() -> Void)?] = [:]
    private(set) var alertTitle = "?"
    private(set) var alertBody = "?"
    
    enum CurrentScreen {
        case landing
        case dashboard
        
        var backgroundColor: Color {
            return .init(rRed: 240, gGreen: 241, bBlue: 245)
        }
    }
    
    enum ActiveModal: Identifiable {
        case registerDevice
        case devMenu
        
        var id: Int {
            hashValue
        }
    }
    
    init() {
        isDevMode = ALTEnvironment.current == .dev || ALTEnvironment.current == .qa
        NotificationCenter.default.addObserver(self, selector: #selector(revokedHandler),
                                               name: NotificationService.Key.revokedNote.name, object: nil)
        requestCameraAuthIfNeeded()
    }
}

// MARK: - Private
private extension DeviceRegistrationLandingDriver {
    @objc
    func revokedHandler() {
        isRegistered = securityService.isDeviceRegistered
    }
    
    func setupActionSheet() {
        actionSheetBtns["Check CRL"] = { [weak self] in
            self?.securityService.checkCertificateRevocationList()
        }
        actionSheetBtns["Reset Registration"] = { [weak self] in
            self?.securityService.resetDeviceRegistered()
        }
    }
    
    func requestCameraAuthIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if !granted {
                    self?.showAlert(title: R.string.localizable.cameraDenied(),
                                    body: R.string.localizable.accessToCameraDenied())
                }
            }
        case .restricted, .denied:
            self.showAlert(title: R.string.localizable.cameraDenied(),
                           body: R.string.localizable.accessToCameraDenied())
        case .authorized: break
        @unknown default:
            logger.error("AVCaptureDevice authorizationStatus hit unknown case")
        }
    }
    
    func showAlert(title: String, body: String) {
        alertTitle = title
        alertBody = body
        
        showAlert.toggle()
    }
}
