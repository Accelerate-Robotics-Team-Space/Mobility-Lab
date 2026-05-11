//
//  AnalyticsDriver.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/9/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import GRDB
import SwiftUI

final class AnalyticsDriver: ObservableObject {
    static var num = 0
    
    private let manager: PatientManagerProtocol
    private var updateTimeLineTimer: Timer?
    private var updateCurrentPosTimer: Timer?
    private lazy var stringToDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd"
        return formatter
    }()
    private(set) var firstDay = Date()

    @Published var sessionId: String?
    @Published var timeLineDict: [Int64: ActivityStartEnd] = [:]
    @Published var positionDurations: [PositionalFlagCategory: Int64] = [:]
    @Published var selectedDate = Date() {
        didSet {
            selectedDateDidChange(selectedDate)
        }
    }
    @Published var isToday = true
    @Published var isFirstDay = false
    @Published private(set) var analyticsActivityViewModel: AnalyticsActivityViewModel

    // MARK: Services
    private let container: Container
    private let activityService: ActivityLogServiceProtocol
    private let notificationCenter: NotificationCenterServiceProtocol
    private let sessionRepository: any SessionRepositoryProtocol

    private let calendar: Calendar = .autoupdatingCurrent

    // MARK: - Init
    init(using manager: PatientManagerProtocol? = nil, container: Container = .shared) {
        self.container = container
        self.manager = manager ?? container.patientManager.resolve()
        self.activityService = container.activityLogService.resolve()
        self.notificationCenter = container.notificationCenter.resolve()
        self.sessionRepository = container.sessionRepository.resolve()
        self.analyticsActivityViewModel = AnalyticsActivityViewModel(container: container)
        self.selectedDate = Date()
        self.sessionId = self.manager.sessionId
        
		fetchAndUpdateLastSession()
        
        notificationCenter.addObserver(
            self,
            selector: #selector(stopAllTimer),
            name: Notification.Name("enrolling-wearable"),
            object: nil
        )

        startUpdateTimeLineTimer()
        startUpdateCurrentPosTimer()
    }

    var pausedDuration: Int64 {
        let pausedEntries = timeLineDict.values.filter({ $0.isPause })
        let earliest = pausedEntries.map(\.startTime).filter({ $0 != 0 }).min() ?? 0
        let latest = pausedEntries.map(\.endTime).max() ?? 0
        return Int64(latest - earliest) * 1_000
    }

    var wrongDuration: Int64 {
        let wrongEntries = timeLineDict.values.filter({ !$0.isPause && $0.isWrong })
        let durations = wrongEntries.map { ($0.endTime - $0.startTime) }
        let timeInSeconds = Int64(durations.reduce(0.0, +))
        let timeInterval = timeInSeconds * 1_000
        return timeInterval
    }

    fileprivate func fetchAndUpdateLastSession() {
        Task { [weak self] in
            guard let self else { return }
            if let lastSession = await self.sessionRepository.getLastSession() {
                if lastSession.hasEnded {
                    self.activityService.setup(with: self.sessionId)
                } else {
                    self.activityService.resume(with: self.sessionId)
                }
            } else {
                self.activityService.setup(with: self.sessionId)
            }
        }
    }

    func goForward() {
        let nextDay = calendar.date(byAdding: DateComponents(day: 1), to: selectedDate)!
        if nextDay <= Date() {
            selectedDate = nextDay
        }
    }
    
    func goBackward() {
        let previousDay = calendar.date(byAdding: DateComponents(day: -1), to: selectedDate)!
        if previousDay >= firstDay {
            selectedDate = previousDay
        }
    }
    
    func updateUI() {
        var newPositionDurations: [PositionalFlagCategory: Int64] = [:]
        let positionDurationsByDate = self.analyticsActivityViewModel.positionDurationsByDate
        if positionDurationsByDate[selectedDate.formattedDate] != nil {
            newPositionDurations = positionDurationsByDate[selectedDate.formattedDate]!
        }
        self.positionDurations = newPositionDurations
        
        var newActivitiesByDate: [Int64: ALTActivityLog] = [:]
        let activitiesByDatePublisher = self.analyticsActivityViewModel.activitiesByDate
        if activitiesByDatePublisher[selectedDate.formattedDate] != nil {
            newActivitiesByDate = activitiesByDatePublisher[selectedDate.formattedDate]!
        }
        
        self.timeLineDict.removeAll()
        self.positionDurations.removeAll()
        
        if !newActivitiesByDate.isEmpty {
            self.positionDurations = newPositionDurations
            resetDict(activitiesByDate: newActivitiesByDate)
        }
    }

    private func resetDict(activitiesByDate: [Int64: ALTActivityLog]) {
        // Reset dict
        var updates: [ActivityStartEnd] = []
        for activity in activitiesByDate {
            let selectedMidnight = calendar.startOfDay(for: selectedDate)
            var startTime = activity.value.actualPositionStarted.timeIntervalSince(selectedMidnight)
            if startTime < 0 {
                startTime = 0
            } else if startTime > .secondsPerDay {
                startTime = .secondsPerDay
            }
            var endTime = activity.value.actualPositionEnded.timeIntervalSince(selectedMidnight)
            if endTime > .secondsPerDay {
                endTime = .secondsPerDay
            }
            let isPause = activity.value.bmmMonitoringState == PatientMonitorState.onPause.rawValue

            let activityStartEnd = ActivityStartEnd(
                id: activity.key,
                startDate: Date().startOfDay.addingTimeInterval(startTime),
                endDate: Date().startOfDay.addingTimeInterval(endTime),
                actualPosition: PositionalFlagCategory(activity.value.actualPosition),
                targetPosition: PositionalFlagCategory(activity.value.startingTargetPosition),
                startTime: startTime,
                endTime: endTime,
                isPause: isPause
            )

            updates.append(activityStartEnd)
        }
        let updateTuples = updates.map { ($0.id, $0) }
        DispatchQueue.main.async { [weak self, updateTuples] in
            guard let updated = self?.timeLineDict.merging(updateTuples, uniquingKeysWith: { _, new in new }) else {
                return
            }
            self?.timeLineDict = updated
        }
    }

    private func selectedDateDidChange(_ date: Date) {
        isToday = calendar.isDateInToday(date)
        isFirstDay = calendar.dateComponents([.day], from: date, to: firstDay).day == 0
        if isToday {
            startUpdateTimeLineTimer()
            startUpdateCurrentPosTimer()
        } else if isFirstDay {
            stopUpdateTimeLineTimer()
            stopUpdateCurrentPosTimer()
        } else {
            stopUpdateTimeLineTimer()
            stopUpdateCurrentPosTimer()
        }
    }

    @objc
    func updateCurrentPosition() {
        if calendar.dateComponents([.day], from: selectedDate) != calendar.dateComponents([.day], from: Date()) {
            selectedDate = Date()
        }

        let positionDurationsByDate = analyticsActivityViewModel.positionDurationsByDate
        let now = Date.now
        let newPositionDurations: [PositionalFlagCategory: Int64]
        if let todaysDurations = positionDurationsByDate[now.formattedDate] {
            newPositionDurations = todaysDurations
        } else {
            newPositionDurations = [:]
        }

        let firstDayString = Array(positionDurationsByDate.keys).min(by: <) ?? ""
        if !firstDayString.isEmpty {
            let newFirstDay = stringToDateFormatter.date(from: firstDayString) ?? now
            if newFirstDay != firstDay {
                firstDay = newFirstDay
                // Update isFirstDay flag when firstDay changes
                isFirstDay = calendar.startOfDay(for: selectedDate) <= calendar.startOfDay(for: firstDay)
            }
        }

        withAnimation {
            DispatchQueue.main.async { [weak self] in
                self?.positionDurations = newPositionDurations
            }
        }
    }
    
    @objc
    func updateTimeLine() {
        let activitiesByDatePublisher = analyticsActivityViewModel.activitiesByDate
        let newActivitiesByDate: [Int64: ALTActivityLog]
        let now = Date.now
        if let todaysActivity = activitiesByDatePublisher[now.formattedDate] {
            newActivitiesByDate = todaysActivity
        } else {
            newActivitiesByDate = [:]
        }
        var updates: [ActivityStartEnd] = []
        for activity in newActivitiesByDate {
            let todayMidnight = calendar.startOfDay(for: now)
            var startTime = activity.value.actualPositionStarted.timeIntervalSince(todayMidnight)
            if startTime < 0 {
                startTime = 0
            }
            var endTime = activity.value.actualPositionEnded.timeIntervalSince(todayMidnight)
            if endTime > .secondsPerDay {
                endTime = .secondsPerDay
            }
            let isPause = activity.value.bmmMonitoringState == PatientMonitorState.onPause.rawValue

            let activityStartEnd = ActivityStartEnd(
                id: activity.key,
                startDate: now.startOfDay.addingTimeInterval(startTime),
                endDate: now.startOfDay.addingTimeInterval(endTime),
                actualPosition: PositionalFlagCategory(activity.value.actualPosition),
                targetPosition: PositionalFlagCategory(activity.value.startingTargetPosition),
                startTime: startTime,
                endTime: endTime,
                isPause: isPause
            )
            updates.append(activityStartEnd)
        }

        let updateTuples = updates.map { ($0.id, $0) }
        withAnimation {
            DispatchQueue.main.async { [weak self, updateTuples] in
                guard let updated = self?.timeLineDict.merging(updateTuples, uniquingKeysWith: { _, new in new }) else {
                    return
                }
                self?.timeLineDict = updated
            }
        }
    }
    
    func startUpdateTimeLineTimer() {
        stopUpdateTimeLineTimer()
        if updateTimeLineTimer == nil {
            updateTimeLineTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(self.updateTimeLine), userInfo: nil, repeats: true)
        }
    }
    
    func stopUpdateTimeLineTimer() {
        updateTimeLineTimer?.invalidate()
        updateTimeLineTimer = nil
    }
    
    func startUpdateCurrentPosTimer() {
        stopUpdateCurrentPosTimer()
        if updateCurrentPosTimer == nil {
            updateCurrentPosTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(self.updateCurrentPosition), userInfo: nil, repeats: true)
        }
    }
    
    func stopUpdateCurrentPosTimer() {
        updateCurrentPosTimer?.invalidate()
        updateCurrentPosTimer = nil
    }
    
    @objc
    func stopAllTimer() {
        stopUpdateTimeLineTimer()
        stopUpdateCurrentPosTimer()
    }
}
