//
//  BleDataFeedRouter.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/2/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth

struct BleDataFeedRouter: BleRoutable {
    static let std = BleDataFeedRouter()
    
    var service: BleService {
        .dataFeed
    }
    
    var characteristics: [BleCharacteristic] {
        [
            .answerDataFeed,
            .requestDataFeed,
            .rejectDataFeed,
            .requestCalibrationPoint,
            .confirmDataFeed,
            .dataFeed,
            .calibrationPoint,
            .batteryLvl,
            .dataFeedStatus,
            .requestTerminate,
            .terminateAnswer,
            .dismissBatteryLow,
        ]
    }
    
    enum BleCharObj: BleSendable {
        case dataFeed(dataPoint: DataPoint)
        case calibrationPoint(calibrationPoint: DataPoint)
        case requestDataFeed(request: DataFeedRequest)
        case rejectDataFeed(request: DataFeedRequest)
        case requestCalibrationPoint(request: DataFeedRequest)
        case answerDataFeed(answer: DataFeedInitAnswer)
        case confirmDataFeed(confirmation: DataFeedConfirmation)
        case trackingUpdated(isTracking: Bool)
        case batteryLvl(data: BatteryLevelData)
        case requestTerminate(request: JustRequest)
        case terminateAnswer(answer: TerminateConfirmation)
        case dismissBatteryLow(request: JustRequest)
        
        func convertToSendable() -> (BleCharacteristic, Data) {
            switch self {
            case .dataFeed(let dataPoint):
                return (.dataFeed, dataPoint.toData())
            case .rejectDataFeed(let request):
                return (.rejectDataFeed, request.toData())
            case .calibrationPoint(let dataPoint):
                return (.calibrationPoint, dataPoint.toData())
            case .requestDataFeed(let request):
                return (.requestDataFeed, request.toData())
            case .requestCalibrationPoint(let request):
                return (.requestCalibrationPoint, request.toData())
            case .answerDataFeed(let answer):
                return (.answerDataFeed, answer.toData())
            case .confirmDataFeed(let confirmation):
                return (.confirmDataFeed, confirmation.toData())
            case .trackingUpdated(let isTracking):
                return (.dataFeedStatus, isTracking.toData())
            case .batteryLvl(let data):
                return (.batteryLvl, data.toData())
            case .requestTerminate(let request):
                return (.requestTerminate, request.toData())
            case .terminateAnswer(let answer):
                return (.terminateAnswer, answer.toData())
            case .dismissBatteryLow(let request):
                return (.dismissBatteryLow, request.toData())
            }
        }
    }
    
    private init() {}
    
    func decodeData(_ data: Data, for charId: CBUUID) -> BleCharObj? {
        switch BleCharacteristic(using: charId) {
        case .dataFeed:
            guard let newPoint = DataPoint(serialize: data) else { return nil }
            return .dataFeed(dataPoint: newPoint)
        case .calibrationPoint:
            guard let calibrationPoint = DataPoint(serialize: data) else { return nil }
            return .calibrationPoint(calibrationPoint: calibrationPoint)
        case .requestDataFeed:
            guard let newRequest = DataFeedRequest(serialize: data) else { return nil }
            return .requestDataFeed(request: newRequest)
        case .requestCalibrationPoint:
            guard let newCalibrationPointRequest = DataFeedRequest(serialize: data) else { return nil }
            return .requestCalibrationPoint(request: newCalibrationPointRequest)
        case .answerDataFeed:
            guard let newAnswer = DataFeedInitAnswer(serialize: data) else { return nil }
            return .answerDataFeed(answer: newAnswer)
        case .rejectDataFeed:
            guard let requestReject = DataFeedRequest(serialize: data) else { return nil }
            return .rejectDataFeed(request: requestReject)
        case .confirmDataFeed:
            guard let newConfirmation = DataFeedConfirmation(serialize: data) else { return nil }
            return .confirmDataFeed(confirmation: newConfirmation)
        case .batteryLvl:
            guard let data = BatteryLevelData(serialize: data) else { return nil }
            return .batteryLvl(data: data)
        case .dataFeedStatus:
            guard let isTracking = Bool(serialize: data) else { return nil }
            return .trackingUpdated(isTracking: isTracking)
        case .requestTerminate:
            guard let requestTerminate = JustRequest(serialize: data) else { return nil }
            return .requestTerminate(request: requestTerminate)
        case .terminateAnswer:
            guard let terminateConfirmation = TerminateConfirmation(serialize: data) else { return nil }
            return .terminateAnswer(answer: terminateConfirmation)
        case .dismissBatteryLow:
            guard let request = JustRequest(serialize: data) else { return nil }
            return .dismissBatteryLow(request: request)
        default: return nil
        }
    }
}
