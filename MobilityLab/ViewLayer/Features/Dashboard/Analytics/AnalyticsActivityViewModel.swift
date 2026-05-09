//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation

final class AnalyticsActivityViewModel: ObservableObject {
    private let container: Container
    private let activityLogRepository: any ActivityLogRepositoryProtocol
    @Published private var activities: [ALTActivityLog] = []
    @Published var positionDurationsByDate: [String: [PositionalFlagCategory: Int64]] = [:]
    @Published var activitiesByDate: [String: [Int64: ALTActivityLog]] = [:]
    private var cancellables: Set<AnyCancellable> = []

    private lazy var dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = .autoupdatingCurrent
            return formatter
    }()
    private let calendar: Calendar = .autoupdatingCurrent

    init(container: Container = .shared) {
        self.container = container
        self.activityLogRepository = container.activityLogRepository.resolve()
        configureBindings()
    }

    func configureBindings() {
        activityLogRepository
            .activityLogPublisher
            .catch { error -> AnyPublisher<[ALTActivityLog], Never> in
                logger.warn(error.localizedDescription)
                return Just([]).eraseToAnyPublisher()
            }
            .sink { logs in
                self.activities = logs
            }
            .store(in: &cancellables)

        $activities
            .dropFirst()
            .map { activities in activities.filter({ $0.id != nil }) }
            .map { (activities: [ALTActivityLog]) in
                let array = activities.map { ($0.id!, $0) }
                return Dictionary(array, uniquingKeysWith: { left, _ in left })
            }
            .map { (activityDict: [Int64: ALTActivityLog]) -> [String: [Int64: ALTActivityLog]] in
                var activitiesByDate: [String: [Int64: ALTActivityLog]] = [:]
                for entry in activityDict where entry.value.bmmMonitoringState != PatientMonitorState.onStart.rawValue {
                    let startDate = entry.value.actualPositionStarted
                    let formattedDate = self.dateFormatter.string(from: startDate)
                    if activitiesByDate[formattedDate] == nil {
                        activitiesByDate[formattedDate] = [:]
                    }

                    activitiesByDate[formattedDate]![entry.key] = entry.value
                }
                return activitiesByDate
            }
            .sink { [weak self] (dict: [String: [Int64: ALTActivityLog]]) in
                self?.activitiesByDate = dict
            }
            .store(in: &cancellables)

        $activitiesByDate
            .dropFirst()
            .map { [weak self] (activityByDateDict: [String: [Int64: ALTActivityLog]]) -> [String: [PositionalFlagCategory: Int64]] in
                var positionDurationsByDate: [String: [PositionalFlagCategory: Int64]] = [:]
                guard let self else { return positionDurationsByDate }
                for (dateString, entries) in activityByDateDict {
                    guard let date = Date.fromDateString(dateString: dateString),
                          let nextDay = self.calendar.date(byAdding: .day, value: 1, to: date) else { continue }
                    var durations: [PositionalFlagCategory: Int64] = [:]
                    for activity in Array(entries.values) where activity.bmmMonitoringState == PatientMonitorState.onResume.rawValue {
                        var started = activity.actualPositionStarted
                        if activity.actualPositionStarted < date {
                            started = date
                        }
                        var ended = activity.actualPositionEnded
                        if ended > nextDay {
                            ended = nextDay
                        }
                        let position = PositionalFlagCategory.descriptionToPosition(description: activity.actualPosition)
                        if durations[position] == nil {
                            durations[position] = 0
                        }
                        if !activity.isWrongPosition && activity.bmmMonitoringState != PatientMonitorState.onPause.rawValue {
                            durations[position]! += ended.millisecondsSince1970 - started.millisecondsSince1970
                        } else if activity.actualPosition == PositionalFlagCategory.other.encoded {
                            durations[position]! += ended.millisecondsSince1970 - started.millisecondsSince1970
                        }
                    }
                    positionDurationsByDate[dateString] = durations
                }
                return positionDurationsByDate
            }
            .sink { [weak self] dict in
                self?.positionDurationsByDate = dict
            }
            .store(in: &cancellables)
    }
}
