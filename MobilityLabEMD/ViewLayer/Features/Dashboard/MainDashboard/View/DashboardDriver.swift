//
//  DashboardDriver.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/31/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import SwiftUI

class DashboardDriver: ObservableObject {
    @Injected(\.bmmInfoAPIService) private var bmmInfoService
    @Injected(\.basestationManager) private var basestationManager
    @Injected(\.provisioningAPIService) private var provisioningService
    private var networkMonitor = NetworkMonitor.shared

    @Published var currentBMM: BMMViewModel? {
        didSet {
            oldValue?.isDisplayingDetails = false
            currentBMM?.isDisplayingDetails = true
        }
    }
    @Published var currentSort: SortedBy = .roomBed {
        didSet {
            var bmms: [BMMViewModel] = registeredBMMs
            if !selectedUnitName.isEmpty {
                bmms = registeredBMMs.filter({ bmm in
                    guard !bmm.isStatic else { return true }
                    if bmm.unit != nil {
                        return bmm.unit == selectedUnitName
                    } else {
                        return true
                    }
                })
            }
            if currentSort == .roomBed {
                let sortedByName = bmms.sorted(by: {
                    return $0.roomBed ?? "Unknown" < $1.roomBed ?? "Unknown"
                })
                let unassigned = sortedByName.filter { $0.patientState == .unassigned }
                let noSession = sortedByName.filter { $0.patientState == .noSession }
                let allOthers = sortedByName.filter { ![.noSession, .unassigned].contains($0.patientState) }
                bmms = allOthers + noSession + unassigned
            } else if currentSort == .urgency {

                let criticals = bmms.filter { $0.currentAlert == .critical && !$0.isLostSignal }
                    .sorted(by: { $0.currentAlert > $1.currentAlert })
                let lowBattery = criticals.filter { $0.bmmState == .lowBattery }
                let nonLowBatteryCriticals = criticals.filter { $0.bmmState != .lowBattery }

                let allOthers = bmms.filter { $0.currentAlert != .critical && !$0.isLostSignal }
                    .sorted(by: { $0.patientState?.rawValue ?? 9 > $1.patientState?.rawValue ?? 9 })

                let lostSignalCards = bmms.filter {
                    $0.isLostSignal && ![.noSession, .unassigned].contains($0.patientState)
                }
                let unassigned = bmms.filter { $0.patientState == .unassigned }
                let noSession = bmms.filter { $0.patientState == .noSession }

                bmms = lostSignalCards + lowBattery + nonLowBatteryCriticals + allOthers + noSession + unassigned
            } else if currentSort == .unit {
                let sortedByName = bmms.displaySorted(by: \.roomBed, fallback: \.id)
                let unassigned = sortedByName.filter { $0.patientState == .unassigned }
                let noSession = sortedByName.filter { $0.patientState == .noSession }
                let allOthers = sortedByName.filter { ![.noSession, .unassigned].contains($0.patientState) }
                bmms = allOthers + noSession + unassigned

                sortedByUnitDict = Dictionary(grouping: bmms, by: { bmm in
                    return bmm.unit ?? "Unassigned"
                })

                var keys = sortedByUnitDict.keys.sorted()
                if let index = keys.firstIndex(of: "Unassigned") {
                    keys.remove(at: index)
                    keys.append("Unassigned")
                }
                sortedByUnitDictKeys = keys
            }
            bmmsToDisplay = bmms
        }
    }
    @Published var isConnected: Bool = false
    @Published var bmmsToDisplay: [BMMViewModel] = []
    var registeredBMMs: [BMMViewModel] = []

    @Published var showSideMenu = false
    @Published var displayList = false
    @Published var expandSorting = false
    var isLoading = false
    @Published var selectedUnitName = "" {
        didSet {
            UserDefaults.standard.selectedFilterUnitName = selectedUnitName
            currentSort = currentSort
        }
    }
    @Published var sortedByUnitDict: [String: [BMMViewModel]] = [:]
    var sortedByUnitDictKeys: [String] = []
    @Published var profileModal: ProfileActiveModal = .none
    @Published var mqttConState = MQTTService.shared.status {
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
    @Published var units: [HospitalUnitInfo] = []
    
    private let formatter = DateComponentsFormatter()
    private let ummRefreshRate: TimeInterval = 2 * 60 // Refresh every 2 minutes
    private var token: AnyCancellable?
    private var ummRefreshLoop: Timer?
    private var canRetry = true

    enum SortedBy {
        case roomBed
        case urgency
        case unit
        
        var name: String {
            switch self {
            case .roomBed:
                return "Room/Bed"
            case .urgency:
                return "Urgency"
            case .unit:
                return "Unit"
            }
        }
    }
    
    enum ProfileActiveModal: Identifiable {
        case posToAvoid
        case location
        case details
        case none

        var id: Int {
            hashValue
        }
    }
    var cancellables: Set<AnyCancellable> = []

    init() {
        MQTTService.shared.delegate = self
        defer {
            self.selectedUnitName = UserDefaults.standard.selectedFilterUnitName ?? ""
            self.currentSort = .roomBed
        }

        // TODO: User MQTTService.statusPublisher instead of Notification Center
        NotificationCenter.default.addObserver(self, selector: #selector(statusHandler), name: MQTTService.statusNote, object: nil)

        #if DEV
        if UserDefaults.standard.facilityId == "5a68f08c-db4b-4763-8c8a-2cb2ebac6d69" { // Atlas Medical Center
            // registeredBMMs = mockAtlasDemoFacilityBMMs
        } else if UserDefaults.standard.facilityId == "93eb34a0-eb8e-4356-9b00-1cf2d9654b7e" {
            registeredBMMs = mockAtlasDemoFacilityBMMs
        }
        #elseif TEST
        if UserDefaults.standard.facilityId == "52a1d9c7-e919-4bd8-8f20-100ed9ee93af" {
            registeredBMMs = mockAtlasDemoFacilityBMMs
        }
        #elseif PROD
        // Atlas demo facility
        if UserDefaults.standard.facilityId == "f751d7d1-034a-4208-83d6-825e5fd131a0" {
            registeredBMMs = mockAtlasDemoFacilityBMMs
            injectMockSensorData(&registeredBMMs)
        }
        // Atlas medical center
        if UserDefaults.standard.facilityId == "6049b1d9-f7d3-4c49-9f84-939fb2c85b11" {
            registeredBMMs = mockAtlasMedicalCenterBMMs
            injectMockSensorData(&registeredBMMs)
        }
        #endif

        ummRefreshLoop = Timer.scheduledTimer(withTimeInterval: ummRefreshRate, repeats: true) { [weak self] _ in
            self?.refreshBMMs()
        }
        ummRefreshLoop?.fire()
        units = HospitalUnitInfo.getAll()
        networkMonitor.isConnectedPublisher
            .sink { [weak self] in
                self?.isConnected = $0
            }
            .store(in: &cancellables)
    }

    func refreshBMMs() {
        guard isLoading == false else { return }
        guard let ummFromApple = UserDefaults.standard.baseStationFromApple else { return }
        isLoading = true
        Task {
            do {
                let bmms = try await bmmInfoService.fetchBMMList(for: ummFromApple)
                isLoading = false
                await handleBMMsList(bmms)
            } catch {
                isLoading = false
                logger.error("BMM request error \(error.localizedDescription)")
                if canRetry == true && (error as? URLError)?.errorCode == NSURLErrorNetworkConnectionLost {
                    canRetry = false
                    refreshBMMs()
                }
            }
        }
        let serverLastModified = units.max(by: { $0.serverLastModified < $1.serverLastModified })?
            .serverLastModified ?? .distantPast
        self.updateUnitsAndRoomsInDbIfAvailable(dateAfter: UserDefaults.standard.deviceRegistrationTime
                                                ?? DateFormatter.regDateFormatter.string(from: serverLastModified))
    }

    func getBMMsStatus() {
        guard isLoading == false else { return }
        guard let ummFromApple = UserDefaults.standard.baseStationFromApple else { return }
        logger.debug("Requested BMM statuses")
        self.isLoading = true
        Task {
            do {
                let bmmStatuses = try await bmmInfoService.fetchBMMStatuses(for: ummFromApple)
                await handleBMMsStatuses(bmmStatuses)
            } catch {
                logger.error("BMM statuses error \(error.localizedDescription)")
                if self.canRetry == true && (error as? URLError)?.errorCode == NSURLErrorNetworkConnectionLost {
                    self.canRetry = false
                    self.getBMMsStatus()
                }
            }
        }
    }

    private func updateUnitsAndRoomsInDbIfAvailable(dateAfter: String) {
        Task {
            do {
                let isUnitAdded = try await provisioningService.checkIfUnitRoomsAdded(dateAfter).unitsOrRoomsUpdated
                if isUnitAdded {
                    let updatedData = try await provisioningService.getUnitRooms(dateAfter)

                    for var unit in updatedData.units {
                        unit.saveToDB()
                    }
                    for var roomBed in updatedData.roomBeds {
                        roomBed.saveToDB()
                    }
                    UserDefaults.standard.deviceRegistrationTime = DateFormatter.regDateFormatter.string(from: Date())
                }
            } catch {
                logger.error("Fetching units or rooms failed. Error:\(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func handleBMMsList(_ bmms: [BMMStruct]) {
        logger.debug("Received BMMS")
        self.isLoading = false
        self.canRetry = true
        let isFirstDownload =
        self.registeredBMMs.isEmpty ||
        self.registeredBMMs == self.mockAtlasMedicalCenterBMMs ||
        self.registeredBMMs == self.mockAtlasDemoFacilityBMMs
        for bmm in bmms where self.registeredBMMs.contains(where: { $0.id == bmm.id }) == false {
            self.registeredBMMs.append(
                BMMViewModel(
                    id: bmm.id,
                    deviceId: bmm.deviceSerialNumber,
                    lastSeen: bmm.bmmLastSeen,
                    turnProtocol: bmm.bmmLastSeen?.turnProtocol ?? "",
                    complianceAngle: bmm.bmmLastSeen?.complianceDegree ?? -1,
                    positionsToAvoid: [],
                    patientDetailsViewModel: .init(id: bmm.bmmLastSeen?.patientIdentifier ?? "No ID")
                )
            )
        }
        self.currentSort = self.currentSort
        Task { @MQTTActor [weak self] in
            guard let self else { return }
            self.basestationManager.subscribe(to: self.registeredBMMs.map({ $0.id }))
        }
        if isFirstDownload {
            self.getBMMsStatus()
        }
    }

    @MainActor
    private func handleBMMsStatuses(_ bmms: [BMMStatus]) {
        logger.debug("Received BMM statuses")
        self.isLoading = false
        self.canRetry = true
        var filtered: [BMMStatus] = []
        var store: [String: Int] = [:]
        bmms.sorted(by: { $0.sessionStartTime > $1.sessionStartTime })
            .forEach { status in
                let key = status.roomBed + status.facilityUnitName
                if store[key, default: 0] == 0 {
                    filtered.append(status)
                    store[key] = 1
                }
            }
        filtered.forEach { bmmStatus in
            self.registeredBMMs.first(with: bmmStatus.bmmId)?
                .fillFrom(bmmStatus: bmmStatus)
        }
    }

    func resetRegistration() {
        ummRefreshLoop?.invalidate()
        ummRefreshLoop = nil
        registeredBMMs = []
        bmmsToDisplay = []
        basestationManager.reset()
        UserDefaults.standard.reset()
        Keychain.shared.reset()
        HospitalRoomBed.deleteAllFromDB()
        HospitalUnit.deleteAllFromDB()

        NotificationCenter.default.post(name: NotificationService.Key.revokedNote.name, object: nil)
    }
}

extension DashboardDriver: MQTTDelegate {
    func update(from baseStation: String, rollAngle: Double, pitchAngle: Double) {
        registeredBMMs.first(with: baseStation)?
            .update(roll: rollAngle, pitch: pitchAngle)
    }
    
    func updateDataPoint(topic: String, from baseStation: String, with: String) {
        registeredBMMs.first(with: baseStation)?
            .update(data: with, topic: topic)
        currentSort = currentSort // refresh sort
    }
    
    func updateWearableBatteryLvl(from baseStation: String, wearableId: String, value: String) {
        guard let decodedJson = try? JSONDecoder().decode(Wearable.self, from: value.toData()) else { return }
        guard let currentWearable = registeredBMMs.first(with: baseStation)?.currentWearable else {
            registeredBMMs.first(with: baseStation)?
                .update(wearable: WearableViewModel(id: wearableId.uppercased(),
                                                    wearableSerialNum: decodedJson.wearableSerialNumber.formattedId()),
                        newBatteryLevel: Int(decodedJson.wearableBatLvl) ?? 0)
            return
        }
        registeredBMMs.first(with: baseStation)?
            .update(wearable: currentWearable,
                    newBatteryLevel: Int(decodedJson.wearableBatLvl) ?? 0)
    }
}

private extension DashboardDriver {
    // MARK: - @Objc
    @objc
    func statusHandler() {
        mqttConState = MQTTService.shared.status
        if MQTTService.shared.status == .connected && !registeredBMMs.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.getBMMsStatus()
            }
        }
    }
}

private extension PatientDetailsViewModel {
    static var mock: PatientDetailsViewModel {
        PatientDetailsViewModel(
            id: "an id",
            weightInPounds: 128,
            heightInInches: 64,
            sex: .male
        )
    }
}

private extension DashboardDriver {

    private var mockAtlasDemoFacilityBMMs: [BMMViewModel] { [
        // Overdue
        BMMViewModel(id: "ICUOverdue", deviceId: "ICU006", unit: "ICU", roomBed: "D200-A", bmmState: .connected,
                     sensorState: .connected, patientState: .overdue, timeRemaining: TimeInterval(-400), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: -2.4,
                     pitchAngle: 1.0, batteryPercentage: 42, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Non-Target
        BMMViewModel(id: "ICUNonTarget", deviceId: "ICU007", unit: "ICU", roomBed: "T100-A", bmmState: .connected,
                     sensorState: .connected, patientState: .nonTargetPosition, timeRemaining: TimeInterval(3000), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: -2.4,
                     pitchAngle: 1.0, batteryPercentage: 42, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Turn Soon
        BMMViewModel(id: "ICUTurnSoonYellow", deviceId: "ICU001", unit: "ICU", roomBed: "E-425", bmmState: .connected,
                     sensorState: .connected, patientState: .active, timeRemaining: TimeInterval(600), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: 0,
                     pitchAngle: 0, batteryPercentage: 87, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Paused
        BMMViewModel(id: "ICUPaused", deviceId: "ICU005", unit: "ICU", roomBed: "P300-A", bmmState: .connected,
                     sensorState: .connected, patientState: .paused, timeRemaining: TimeInterval(6000), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: -2.4,
                     pitchAngle: 1.0, batteryPercentage: 42, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Monitoring Left
        BMMViewModel(id: "ICUMonitoringL", deviceId: "ICU002", unit: "ICU", roomBed: "C2-201B", bmmState: .connected,
                     sensorState: .connected, patientState: .active, timeRemaining: TimeInterval(5941), turnProtocol: "", complianceAngle: 0,
                     currentPos: .left, targetPos: .left, rollAngle: 33.7,
                     pitchAngle: 4.3, batteryPercentage: 93, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Monitoring Right
        BMMViewModel(id: "ICUMonitoringR", deviceId: "ICU003", unit: "ICU", roomBed: "C2-202B", bmmState: .connected,
                     sensorState: .connected, patientState: .active, timeRemaining: TimeInterval(5941), turnProtocol: "", complianceAngle: 0,
                     currentPos: .right, targetPos: .right, rollAngle: 33.7,
                     pitchAngle: 4.3, batteryPercentage: 93, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Monitoring Supine
        BMMViewModel(id: "ICUMonitoringS", deviceId: "ICU004", unit: "ICU", roomBed: "C2-203B", bmmState: .connected,
                     sensorState: .connected, patientState: .active, timeRemaining: TimeInterval(5941), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: 33.7,
                     pitchAngle: 4.3, batteryPercentage: 93, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
    ]
    }
    private var mockAtlasMedicalCenterBMMs: [BMMViewModel] { [
        // Low Battery
        BMMViewModel(id: "ICULowBattery", deviceId: "ICU001", unit: "ICU", roomBed: "D200-A", bmmState: .connected,
                     sensorState: .lowBattery, patientState: .active, timeRemaining: TimeInterval(4000), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: -2.4,
                     pitchAngle: 1.0, batteryPercentage: 5, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Turn Soon
        BMMViewModel(id: "ICUTurnSoonYellow", deviceId: "ICU002", unit: "ICU", roomBed: "E-425", bmmState: .connected,
                     sensorState: .connected, patientState: .active, timeRemaining: TimeInterval(600), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: 0,
                     pitchAngle: 0, batteryPercentage: 87, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Non-Target
        BMMViewModel(id: "ICUNonTarget", deviceId: "ICU003", unit: "ICU", roomBed: "T100-A", bmmState: .connected,
                     sensorState: .connected, patientState: .nonTargetPosition, timeRemaining: TimeInterval(3000), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: -2.4,
                     pitchAngle: 1.0, batteryPercentage: 42, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Paused
        BMMViewModel(id: "ICUPaused", deviceId: "ICU004", unit: "ICU", roomBed: "P300-A", bmmState: .connected,
                     sensorState: .connected, patientState: .paused, timeRemaining: TimeInterval(6000), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: -2.4,
                     pitchAngle: 1.0, batteryPercentage: 42, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Monitoring Left
        BMMViewModel(id: "ICUMonitoringL", deviceId: "ICU005", unit: "ICU", roomBed: "C2-201B", bmmState: .connected,
                     sensorState: .connected, patientState: .active, timeRemaining: TimeInterval(5941), turnProtocol: "", complianceAngle: 0,
                     currentPos: .left, targetPos: .left, rollAngle: 33.7,
                     pitchAngle: 4.3, batteryPercentage: 93, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Monitoring Right
        BMMViewModel(id: "ICUMonitoringR", deviceId: "ICU006", unit: "ICU", roomBed: "C2-202B", bmmState: .connected,
                     sensorState: .connected, patientState: .active, timeRemaining: TimeInterval(5000), turnProtocol: "", complianceAngle: 0,
                     currentPos: .right, targetPos: .right, rollAngle: 33.7,
                     pitchAngle: 4.3, batteryPercentage: 93, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Monitoring Supine
        BMMViewModel(id: "ICUMonitoringS", deviceId: "ICU007", unit: "ICU", roomBed: "C2-203B", bmmState: .connected,
                     sensorState: .connected, patientState: .active, timeRemaining: TimeInterval(4000), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: 33.7,
                     pitchAngle: 4.3, batteryPercentage: 93, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Monitoring Partial Left
        BMMViewModel(id: "ICUMonitoringPL", deviceId: "ICU008", unit: "ICU", roomBed: "C2-204B", bmmState: .connected,
                     sensorState: .connected, patientState: .active, timeRemaining: TimeInterval(3000), turnProtocol: "", complianceAngle: 0,
                     currentPos: .partialLeft, targetPos: .left, rollAngle: 33.7,
                     pitchAngle: 4.3, batteryPercentage: 93, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
        // Lost Signal
        BMMViewModel(id: "ICULostSignal", deviceId: "ICU009", unit: "ICU", roomBed: "C2-205B", bmmState: .connected,
                     sensorState: .disconnected, patientState: .active,
                     timeRemaining: TimeInterval(-215), turnProtocol: "", complianceAngle: 0,
                     currentPos: .supine, targetPos: .supine, rollAngle: 33.7,
                     pitchAngle: 4.3, batteryPercentage: 93, positionsToAvoid: [], patientDetailsViewModel: .mock, isStatic: true),
    ]
    }
     func injectMockSensorData(_ bmms: inout [BMMViewModel]) {
         for bmm in bmms {
             if bmm.id == "ICULowBattery" {
                 bmm.cardData.sensorBatteryPercentage = Int.random(in: 11...20)
                 bmm.cardData.bmmBatteryPercentage = Int.random(in: 21...100)
             } else if bmm.id == "ICULostSignal" {
                 bmm.cardData.bmmBatteryPercentage = Int.random(in: 21...100)
             } else if bmm.id == "ICUMonitoringL" {
                 bmm.cardData.rollAngle = 38
                 bmm.cardData.sensorBatteryPercentage = Int.random(in: 21...100)
                 bmm.cardData.bmmBatteryPercentage = Int.random(in: 21...100)
             } else if bmm.id == "ICUMonitoringR" {
                 bmm.cardData.rollAngle = -35
                 bmm.cardData.sensorBatteryPercentage = Int.random(in: 21...100)
                 bmm.cardData.bmmBatteryPercentage = Int.random(in: 21...100)
             } else if bmm.id == "ICUMonitoringS" {
                 bmm.cardData.rollAngle = 0
                 bmm.cardData.sensorBatteryPercentage = Int.random(in: 21...100)
                 bmm.cardData.bmmBatteryPercentage = Int.random(in: 21...100)
             } else if bmm.id == "ICUMonitoringPL" {
                 bmm.cardData.rollAngle = 25
                 bmm.cardData.sensorBatteryPercentage = Int.random(in: 21...100)
                 bmm.cardData.bmmBatteryPercentage = Int.random(in: 21...100)
             } else if bmm.id == "ICUNonTarget" {
                 bmm.cardData.rollAngle = 60
                 bmm.cardData.sensorBatteryPercentage = Int.random(in: 21...100)
                 bmm.cardData.bmmBatteryPercentage = Int.random(in: 21...100)
             } else {
                 bmm.cardData.sensorBatteryPercentage = Int.random(in: 21...100)
                 bmm.cardData.bmmBatteryPercentage = Int.random(in: 21...100)
             }
        }
    }
}
