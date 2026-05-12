//
//  WorkoutHistoryView.swift
//  MobilityLab
//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct WorkoutHistoryView: View {
    @ObservedObject var viewModel: MobilityTrackingViewModel
    @State private var selectedActivity: ActivityRecord?

    private let past7Days: [Date] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).map { cal.date(byAdding: .day, value: -$0, to: today)! }
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Day picker strip
            dayPickerStrip
                .padding(.bottom, 8)

            // Selected day header
            Text(headerText(for: viewModel.selectedHistoryDate))
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.charcoal1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            // Activities for selected day
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.historyActivities) { activity in
                        ActivityListItem(activity: activity)
                            .onTapGesture { selectedActivity = activity }
                    }

                    if viewModel.historyActivities.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.walk.motion")
                                .font(.system(size: 40))
                                .foregroundColor(.charcoal3.opacity(0.4))
                            Text("No activities on this day")
                                .font(.custom("Avenir", size: 15))
                                .foregroundColor(.charcoal3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailView(activity: activity, viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadHistoryForDate(viewModel.selectedHistoryDate)
        }
    }

    // MARK: - Day Picker

    @ViewBuilder
    private var dayPickerStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(past7Days, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedHistoryDate)
                    Button {
                        viewModel.loadHistoryForDate(date)
                    } label: {
                        VStack(spacing: 4) {
                            Text(dayOfWeek(date))
                                .font(.custom("Avenir", size: 11))
                                .foregroundColor(isSelected ? .white : .charcoal3)
                            Text(dayNumber(date))
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(isSelected ? .white : .charcoal1)
                        }
                        .frame(width: 44, height: 54)
                        .background(isSelected ? Color.indigo1 : Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.04), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private func dayOfWeek(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }

    private func dayNumber(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }

    private func headerText(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Today"
        } else if cal.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEEE, MMM d"
            return fmt.string(from: date)
        }
    }
}
