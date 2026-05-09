//
//  ProfileDriver.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/9/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

@MainActor
final class ProfileDriver: ObservableObject {
    enum ProfileError: Error {
        case baseStationIDNotFound
        case facilityIDNotFound
    }

    enum ProfileActiveModal: Identifiable {
        case posToAvoid
        case location
        case details

        var id: Int {
            hashValue
        }
    }

    @Published var modal: ProfileActiveModal?
    @Published var patientLocationDriver: PatientLocationDriver
	@Published var canShowEndReminder: Bool = false
	@Published var endMonitoringState: ProfileDriver.EndMonitoringState = .none {
		didSet {
            // Why do we want to disable the "End Monitoring" button? Won't this prevent retries?
            // Commenting out for now, probably need to remove `endSessionEnabled`
            // endSessionEnabled = [.none, .error].contains(endMonitoringState)
			processEndMonitoringState()
		}
	}
	private weak var patientMonitorDriver: PatientMonitorProtocol?
    @Published var endSessionEnabled: Bool = true

    // MARK: Services
    private let container: Container
    private let userDefaults: BMMUserDefaultsServiceProtocol
    private let provisioningAPIService: ProvisioningAPIServiceProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let patientManager: PatientManagerProtocol

	private(set) var currentPatient: ALTPatient
	private(set) var endMonitoringError: String?

    init(_ patient: ALTPatient, container: Container = .shared) {
        self.container = container
        self.userDefaults = container.userDefaults.resolve()
        self.provisioningAPIService = container.provisioningAPIService.resolve()
        self.networkMonitor = container.networkMonitor.resolve()
        self.patientManager = container.patientManager.resolve()
        self.patientLocationDriver = PatientLocationDriver(container: container)
        self.currentPatient = patient
    }

    func set(patientMonitor: PatientMonitorProtocol) {
        self.patientMonitorDriver = patientMonitor
    }

    func stopSession() async throws {
        guard let baseStationID = userDefaults.baseStationGuid else {
            throw ProfileError.baseStationIDNotFound
        }
        guard let facilityID = userDefaults.facilityId else {
            throw ProfileError.facilityIDNotFound
        }
        logger.info("EndSession: Stop Session")
        let result = try await provisioningAPIService.endPatientSession(
            .init(
                baseStationId: baseStationID,
                facilityId: facilityID,
                patientDetails: .init(
                    patientId: currentPatient.id,
                    sex: currentPatient.sex,
                    weight: currentPatient.weightLbs,
                    height: currentPatient.heightIn,
                    bmi: currentPatient.bmi,
                    hasPaceMaker: currentPatient.hasPaceMaker,
                    hasSternumSkinBroken: currentPatient.hasSternumSkinBroken,
                    props: currentPatient.props,
                    roomBedId: currentPatient.hospitalRoomBedId,
                    facilityUnitId: currentPatient.roomBed?.facilityUnitId ?? "",
                    turnProtocol: userDefaults.turnProtocol!.rawValue,
                    complianceDegree: userDefaults.complianceAngle!.intValue
                )
            )
        )
        if let exception = result["exceptionCode"] as? String {
            throw Self.ProfileDriverError.endMonitoring(exception)
        } else {
            canShowEndReminder = true
        }
	}
	
	func processEndMonitoringState() {
        switch endMonitoringState {
        case .syncingLogs(let attempt):
            logger.info("EndSession: Process EndMonitoring State: syncingLogs(attempt: \(attempt + 1))")
        default:
            logger.info("EndSession: Process EndMonitoring State: \(endMonitoringState)")
        }
        Task { [weak self, patientMonitorDriver] in
            do {
                switch self?.endMonitoringState {
                case .syncingLogs(let attempt):
                    guard self?.networkMonitor.isConnected == true else {
                        logger.info("EndSession: No Internet Connection")
                        throw ProfileDriver.ProfileDriverError.endMonitoring("No Internet connection!")
                    }
                    patientMonitorDriver?.stopTimersAndUpdates()
                    guard attempt < 20 else {
                        DispatchQueue.main.async {
                            self?.endMonitoringState = .error
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        self?.endMonitoringState = .endingInitiated
                    }
                    await patientMonitorDriver?.syncLogs()
                    if patientMonitorDriver?.syncingLogs.isEmpty == true {
                        logger.debug("EndSession: Logs Synced after \(attempt + 1) attempts")
                        DispatchQueue.main.async {
                            self?.endMonitoringState = .backendEndMonitoring
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.endMonitoringState = .syncingLogs(attempt: attempt + 1)
                        }
                        logger.error("EndSession: SyncingLogs is not empty: \(patientMonitorDriver?.syncingLogs ?? [:])")
                    }
                case .backendEndMonitoring:
                    guard self?.networkMonitor.isConnected == true else {
                        logger.info("EndSession: No Internet Connection")
                        throw ProfileDriver.ProfileDriverError.endMonitoring("No Internet connection!")
                    }
                    DispatchQueue.main.async {
                        patientMonitorDriver?.syncingLogs = [:]
                    }
                    Task {
                        do {
                            try await self?.stopSession()
                            DispatchQueue.main.async {
                                self?.endMonitoringState = .done
                            }
                        } catch {
                            logger.error("EndSession: Error: \(error)")
                        }
                    }
                case .done:
                    Task {
                        await patientMonitorDriver?.endSession()
                        self?.patientManager.stopSession()
                    }
                    Timer.scheduledTimer(withTimeInterval: 7, repeats: false) { _ in
                        DispatchQueue.main.async { [weak self] in
                            self?.endMonitoringState = .none
                        }
                    }
                default:
                    logger.info("EndSession: No action needed \(self?.endMonitoringState ?? .none)")
                }
            } catch {
                DispatchQueue.main.async {
                    self?.endMonitoringError = error.localizedDescription
                    logger.error("EndSession: Error \(error)")
                    self?.endMonitoringState = .error
                }
            }
        }
    }
}

extension ProfileDriver {
    enum EndMonitoringState: Hashable {
        case none
        case syncingLogs(attempt: Int)
        case endingInitiated
        case backendEndMonitoring
        case error
        case done

        static func == (lhs: EndMonitoringState, rhs: EndMonitoringState) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none),
                 (.endingInitiated, .endingInitiated),
                 (.backendEndMonitoring, .backendEndMonitoring),
                 (.error, .error),
                 (.done, .done):
                true
            case (.syncingLogs(let lhsCount), .syncingLogs(let rhsCount)):
                lhsCount == rhsCount
            default:
                false
            }
        }
    }

	enum ProfileDriverError: Error, LocalizedError {
		case endMonitoring(String)
		
		var errorDescription: String? {
			switch self {
			case .endMonitoring(let message):
				return message
			}
		}
	}
}
