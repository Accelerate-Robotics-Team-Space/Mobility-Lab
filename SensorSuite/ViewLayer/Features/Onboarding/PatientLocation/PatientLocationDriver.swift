//
//  PatientLocationDriver.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/17/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation

class PatientLocationDriver: ObservableObject {
    enum LocationError: Error {
        case lostSelf
    }

    @Published var selectedUnitStr: String?
    @Published var selectedRoomBedStr: String? {
        didSet {
			canGoNext = !isRoomBedFieldDisabled && selectedRoomBedStr != R.string.localizable.selectPatientRoom()
        }
    }
    @Published var showContraindications = true
    @Published var showPacemakerWarning = false
    @Published var showBrokenSkinWarning = false
    @Published var canGoNext = false
    @Published var unitInfo: [HospitalUnitInfo] = []

    private(set) var roomBedItems: [HospitalRoomBed] = []
    private(set) var selectedUnit: HospitalUnitInfo? {
        didSet {
            selectedUnitStr = selectedUnit?.name
        }
    }
    
    private(set) var selectedRoomBed: HospitalRoomBed? {
        didSet {
            selectedRoomBedStr = selectedRoomBed?.roomBedNumber
        }
    }

    // MARK: Services
    private let hospitalUnitRepository: any HospitalUnitRepositoryProtocol
    private let hospitalRoomBedRepository: any HospitalRoomBedRepositoryProtocol
    private let patientManager: PatientManagerProtocol
    private let patientRepository: any PatientRepositoryProtocol
    private let provisioningAPIService: ProvisioningAPIServiceProtocol
    private let userDefaults: BMMUserDefaultsServiceProtocol

    private let formatter = DateFormatter.regDateFormatter
    var isRoomBedFieldDisabled: Bool {
        return selectedUnitStr == nil
		|| selectedRoomBedStr == R.string.localizable.noRoomsAvailable()
		|| selectedRoomBedStr == R.string.localizable.checkingRoomAvailability()
		|| selectedRoomBedStr == R.string.localizable.failedToFetchRooms()
    }
	var cancellables: Set<AnyCancellable> = []

    // MARK: - Init
    init(manager: PatientManagerProtocol? = nil, container: Container = .shared) {
        self.patientManager = manager ?? container.patientManager.resolve()
        self.hospitalUnitRepository = container.hospitalUnitRepository.resolve()
        self.hospitalRoomBedRepository = container.hospitalRoomBedRepository.resolve()
        self.patientRepository = container.patientRepository.resolve()
        self.provisioningAPIService = container.provisioningAPIService.resolve()
        self.userDefaults = container.userDefaults.resolve()

        self.updateUnitsAndRoomsInDB()
    }

    private func updateUnitsAndRoomsInDB() {
        Just(())
            .flatMap { [weak self] _ -> Future<(), Never> in
                // Make sure we've refreshed our units from DB
                Future { promise in
                    Task {
                        guard let self else {
                            promise(.success(()))
                            return
                        }
                        await self.fetchHospitalUnitInfo()
                        promise(.success(()))
                    }
                }
            }
            .flatMap { [weak self] _ -> AnyPublisher<UnitRoomModel, Error> in
                guard let self else { return Empty().setFailureType(to: Error.self).eraseToAnyPublisher() }
                return self.provisioningAPIService.getUnitRooms(nil)
            }
            .sink { [weak self] (result: Subscribers.Completion<any Error>) in
                switch result {
                case .finished:
                    Task { @MainActor in
                        await self?.fetchHospitalUnitInfo()

                        if let patient = self?.patientManager.currentPatient {
                            self?.updateView(using: patient)
                        } else {
                            await self?.fetchAndUpdatePatient()
                        }
                    }
                case .failure(let error):
                    logger.error(error.localizedDescription)
                }
            } receiveValue: { [weak self] (updatedData: UnitRoomModel) in
                guard let self else {
                    return
                }

                hospitalUnitRepository.update(newUnits: updatedData.units, newRoomBeds: updatedData.roomBeds, existing: self.unitInfo)

                self.userDefaults.deviceRegistrationTime = self.formatter.string(from: .now)
            }
            .store(in: &cancellables)
    }

    private func fetchHospitalUnitInfo() async {
        let allUnits = await hospitalUnitRepository.getAll().displaySorted(by: \.name, fallback: \.id)
        await MainActor.run {
            if !allUnits.isEmpty {
                self.unitInfo = allUnits
                self.roomBedItems = []
            } else {
                self.unitInfo = HospitalUnitInfo.previewUnits
                self.roomBedItems = []
            }
        }
    }

    // MARK: - Util
    @MainActor                                     // completion is for testing
    func selectUnit(_ hospitalUnit: HospitalUnitInfo, completion: ((Error?) -> Void)? = nil) {
        selectedUnit = hospitalUnit
        self.selectedRoomBedStr = R.string.localizable.checkingRoomAvailability()
        self.provisioningAPIService.getAvailableRoomBed(hospitalUnit.id)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .finished: completion?(nil)
                    case .failure(let error):
                        logger.error(error.localizedDescription)
                        self?.selectedRoomBedStr = R.string.localizable.failedToFetchRooms()
                        completion?(error)
                    }
                },
                receiveValue: { [weak self] roomBeds in
                    self?.roomBedItems = roomBeds.displaySorted(by: \.roomBedNumber, fallback: \.id)

                    if self?.selectedUnit?.id == self?.patientManager.currentPatient?.roomBed?.facilityUnitId {
                        self?.selectedRoomBed = self?.patientManager.currentPatient?.roomBed
                        if let roomBedNumber = self?.patientManager.currentPatient?.roomBed, !roomBeds.contains(where: { $0 == roomBedNumber }) {
                            self?.roomBedItems.append(roomBedNumber)
                        }
                        self?.roomBedItems = self?.roomBedItems.displaySorted(by: \.roomBedNumber, fallback: \.id) ?? []
                        return
                    }

                    if roomBeds.isEmpty {
                        self?.selectedRoomBedStr = R.string.localizable.noRoomsAvailable()
                    } else if roomBeds.count == 1 {
                        self?.selectFirstRoomBedItem()
                    } else {
                        self?.selectedRoomBedStr = R.string.localizable.selectPatientRoom()
                    }
                }
            )
            .store(in: &cancellables)
    }
	
	func selectFirstRoomBedItem() {
		selectedRoomBed = roomBedItems.first
	}

    @MainActor
    func selectRoomBed(_ roomBed: HospitalRoomBed) {
        selectedRoomBed = roomBed
    }
    
    func getUnitFromName(_ unitName: String) -> HospitalUnitInfo? {
        for unit in unitInfo where unit.name == unitName { return unit }
        return nil
    }
    
    func getRoomBedItemFromNumber(_ roomBedNumber: String) -> HospitalRoomBed? {
        for roomBeds in roomBedItems where roomBeds.roomBedNumber == roomBedNumber { return roomBeds }
        return nil
    }
    
    func goNextBtnPress(completion: @escaping (() -> Void)) {
        guard let unit = selectedUnit,
              let roomBed = selectedRoomBed,
              unit.name == selectedUnitStr,
              roomBed.roomBedNumber == selectedRoomBedStr else {
            return
        }

        patientManager.updatePatientLocation(hospitalUnit: unit, roomBed: roomBed)
        completion()
    }

    func resetFromPatient() {
        guard let patient = patientManager.currentPatient else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateView(using: patient)
        }
    }
}

// MARK: - Private
private extension PatientLocationDriver {
    func fetchAndUpdatePatient() async {
        do {
            guard let patient = try await patientRepository.latestPatient() else {
                logger.warn("No Patient Found")
                return
            }
            updateView(using: patient)
        } catch {
            logger.error(error.localizedDescription)
        }
    }
	
    func updateView(using somePatient: ALTPatient?) {
        guard let lastPatient = somePatient,
              let unit = unitInfo.first(where: { $0.id == lastPatient.roomBed?.facilityUnitId }) else {
            return
        }
        if self.selectedUnit != unit {
            DispatchQueue.main.async { [weak self] in
                self?.selectUnit(unit)
            }
        }

        if let roomBed = unit.roomBeds.first(where: { $0.id == lastPatient.hospitalRoomBedId }),
           self.selectedRoomBed != roomBed {
            DispatchQueue.main.async { [weak self] in
                self?.selectRoomBed(roomBed)
            }
        }
    }
}
