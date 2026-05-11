//
//  DashboardDriver.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/30/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import SwiftUI

/// SessionWearableDelegate for DashboardDriver.swift
protocol DashboardDriverSessionWearableDelegate: AnyObject {
    /// Triggers when a wearable is added or removed
    /// - Parameter wearables: Array of connected wearables
    func activeWearablesUpdated(_ wearables: [Wearable])
    
    /// Triggered when a wearable pairing request or confirmation of a request is received
    /// - Parameter feedResult: Enum of the type of request received
    func dataFeedUpdate(_ feedResult: DataFeedResult)
    
    /// Triggered when a wearable is undergo swapping process
    /// - Parameter swappingWearable: Current state of swapping progress (Y - swapping is currently in progress / N - swapping is not in progress)
    /// - Parameter tmpLocation: Hold old wearable's location and pass that to new wearable during setup process
    func swappingProcess(_ swappingWearable: Bool, _ tmpLocation: WearableLocation)
    
    func sensorAttemptToPair(attempingToPair pairing: Bool)
    
    func cancelScan()
}

/**
 This driver is used in DashboardView, PatientMonitorSetupView, WearableCellView
 
 # Usages
 *  Pairing wearable
 * Swapping wearable
 * Receive and act from these wearable's requests:
 * newRequest to pair new wearable -> Pop-up will display to start setup process
 * confirmed _________
 *
 */
final class DashboardDriver: ObservableObject {
    enum PairWearablesModal: Identifiable {
        case wearablesSetup
        case editPositionsToAvoid
        case editPatientLocation
        case editPatientDetail
        case recalibrate

        var id: Int {
            hashValue
        }
    }

    enum DefaultConstants {
        static let calibrateDelay: TimeInterval = 1
        static let answerDelay: TimeInterval = 5
        static let oneSecond: TimeInterval = 1
    }

    /// Display Pop-up setup modal
    @Published var pairWearablesModal: PairWearablesModal?
    /// Used
    @Published var isLoading: Bool = false
    /// Setup wearable finished
    @Published var setupFinished: Bool = false {
        didSet {
            if setupFinished {
                sensorAttempingToPair = false
            }
        }
    }
    /// Is swapping in process
    @Published var swappingInProgress: Bool = false
    /// Temporary hold old wearable's location
    @Published var tmpLocation: WearableLocation = .unknown
    @Published var showDataFeedAlert: Bool = false
    /// Is BMM is connected to any wearable
    @Published var connectedWearables: [Wearable]
    /// If BMM successfully got calibration point
    @Published var calibrated: Bool = false
    /// Display alert
    @Published var showAlert: Bool = false
    /// Stack
    @Published var sensorAttempingToPair: Bool = false
    @Published var instructionStep: [PlacingPatchInstructionStep] = [.openPackage]
    @Published var currentTab: Int = 0
    @Published var mqttConState: MQTTSessionStatus = .disconnected {
        didSet {
            switch mqttConState {
            case .error:
                mqttConText = "Error"
                mqttConStateColor = .red1
            case .closed:
                mqttConText = "Closed"
                mqttConStateColor = .red1
            case .disconnected:
                mqttConText = "Disconnected"
                mqttConStateColor = .red1
            case .connected:
                mqttConText = "Connected"
                mqttConStateColor = .green1
            case .connecting:
                mqttConText = "Connecting"
                mqttConStateColor = .yellow1
            }
        }
    }
    @Published var mqttConStateColor: Color = .red1
    @Published var mqttConText = "Unknown"
    @Published var isConnected: Bool = false
    private let calibrateDelay: TimeInterval
    private let answerDelay: TimeInterval
    private let oneSecondDelay: TimeInterval

    let isDevMode: Bool

    private(set) var patient: ALTPatient
    private(set) var feedRequest: DataFeedRequest?

    private var answerCompletion: ((Bool) -> Void)?
    private var oneSecondTick: Timer?
    private var timeoutTimer: Timer?

    var roomBedNum: String? {
        patientManager.patientLocation?.roomBed.roomBedNumber
    }

    private var cancellables: Set<AnyCancellable> = []

    // MARK: Services
    private let container: Container
    private let patientManager: PatientManagerProtocol
    private let mqttService: MQTTServiceProtocol
    private let notificationCenter: NotificationCenterServiceProtocol
    private let networkMonitor: NetworkMonitorProtocol

    // MARK: - Init
    init(
        using manager: PatientManagerProtocol? = nil,
        container: Container = .shared,
        calibrateDelay: TimeInterval = DefaultConstants.calibrateDelay,
        answerDelay: TimeInterval = DefaultConstants.answerDelay,
        oneSecondDelay: TimeInterval = DefaultConstants.oneSecond
    ) {
        self.container = container
        self.patientManager = manager ?? container.patientManager.resolve()
        self.mqttService = container.mqttService.resolve()
        self.notificationCenter = container.notificationCenter.resolve()
        self.networkMonitor = container.networkMonitor.resolve()
        self.patient = self.patientManager.currentPatient ?? ALTPatient.devPatient
        self.connectedWearables = self.patientManager.wearables
        self.isDevMode = ALTEnvironment.current == .dev || ALTEnvironment.current == .qa
        self.calibrateDelay = calibrateDelay
        self.answerDelay = answerDelay
        self.oneSecondDelay = oneSecondDelay
        self.setupFinished = self.patientManager.turnTrackerInfo?.endDate != nil
        self.patientManager.session?.dashboardDriverSessionWearableDelegate = self
        self.isConnected = networkMonitor.isConnected

        networkMonitor.isConnectedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isConnected = $0
            }
            .store(in: &cancellables)
        mqttConState = mqttService.status

        notificationCenter.addObserver(self, selector: #selector(statusHandler), name: MQTTService.statusNote, object: nil)
    }
    
    init(
        previewWearable: [Wearable],
        container: Container = .shared,
        calibrateDelay: TimeInterval = DefaultConstants.calibrateDelay,
        answerDelay: TimeInterval = DefaultConstants.answerDelay,
        oneSecondDelay: TimeInterval = DefaultConstants.oneSecond
    ) {
        self.container = container
        self.patientManager = PatientManager.preview
        self.mqttService = container.mqttService.resolve()
        self.notificationCenter = container.notificationCenter.resolve()
        self.networkMonitor = container.networkMonitor.resolve()
        self.calibrateDelay = calibrateDelay
        self.answerDelay = answerDelay
        self.oneSecondDelay = oneSecondDelay
        self.patient = ALTPatient.devPatient
        self.connectedWearables = previewWearable
        self.isDevMode = true
        mqttConState = mqttService.status

        notificationCenter.addObserver(self, selector: #selector(statusHandler), name: MQTTService.statusNote, object: nil)
    }
    
    func calibrating(wearableId: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + calibrateDelay) { [weak self] in
            guard let self else { return }
            oneSecondTick = Timer.scheduledTimer(withTimeInterval: oneSecondDelay, repeats: true) { [self] _ in
                if self.oneSecondTick!.timeInterval >= 4 {
                    self.oneSecondTick?.invalidate()
                    self.oneSecondTick = nil
                    self.showAlert = true
                }
                if self.calibrated {
                    self.oneSecondTick?.invalidate()
                    self.oneSecondTick = nil
                } else {
                    self.requestDataLocation(true, wearableId: wearableId) { result in
                        if result {
                            self.isLoading = false
                            self.calibrated = true
                        } else {
                            // Something went wrong
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Util
    func answerRequest(_ answer: Bool, location: WearableLocation, completion: ((Bool) -> Void)?) {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: answerDelay, repeats: false) { [weak self] _ in
            self?.isLoading = false
            self?.showDataFeedAlert = true
        }
        isLoading = true
        patientManager.session?.feedRequestAnswer(answer, atLocation: location)
        answerCompletion = completion
    }
    
    func rejectRequest() {
        isLoading = false
        resetInstructionStep()
        patientManager.session?.rejectDataFeed(wearableId: feedRequest!.wearableId)
    }
    
    func requestDataLocation(_ answer: Bool, wearableId: String, completion: ((Bool) -> Void)?) {
        isLoading = true
        patientManager.session?.feedRequestLocationDataPoint(answer, wearableId: wearableId)
        answerCompletion = completion
    }
    
    func resetSwapping() {
        resetInstructionStep()
        patientManager.session?.swapping(false, wearableLocation: .unknown, calibrationPoint: DataPoint())
    }
    
    func unpair() {
        isLoading = false
        resetInstructionStep()
        patientManager.session?.unpair() // unpair or terminate?
    }

    func userDidSelectPairing() {
        patientManager.session?.pmdsWearableDelegate?.userDidSelectPairing()
    }
}

// MARK: - DashboardSessionWearableDelegate
extension DashboardDriver: DashboardDriverSessionWearableDelegate {
    func swappingProcess(_ swappingWearable: Bool, _ tmpLocation: WearableLocation) {
        swappingInProgress = swappingWearable
        self.tmpLocation = tmpLocation
    }
    
    func activeWearablesUpdated(_ wearables: [Wearable]) {
        connectedWearables = wearables
    }
    
    func dataFeedUpdate(_ feedResult: DataFeedResult) {
        switch feedResult {
        case .newRequest(let request):
            feedRequest = request
            pairWearablesModal = .wearablesSetup
        case .confirmed(let confirmation):
            if answerCompletion == nil {
                showDataFeedAlert.toggle()
            } else {
                answerCompletion?(confirmation.isConfirmed)
            }
            timeoutTimer?.invalidate()
            timeoutTimer = nil
            isLoading = false
        case .calibrationPoint(let gotCalibrationPointSuccess):
            if answerCompletion == nil {
                showDataFeedAlert.toggle()
            } else {
                answerCompletion?(gotCalibrationPointSuccess)
            }
            isLoading = false
        }
    }
    
    func sensorAttemptToPair(attempingToPair pairing: Bool) {
        sensorAttempingToPair = pairing
    }
    
    func cancelScan() {
        pairWearablesModal = nil
        resetInstructionStep()
    }
}

// MARK: - Private Helper
private extension DashboardDriver {
    func resetInstructionStep() {
        instructionStep.removeAll()
        instructionStep.append(.openPackage)
    }

    @objc
    func statusHandler() {
        mqttConState = mqttService.status
    }
}
