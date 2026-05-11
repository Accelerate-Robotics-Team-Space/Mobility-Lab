//
//  MobilityTrackingView.swift
//  MobilityLab
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import HealthKit
import SwiftUI

// MARK: - Home View (Landing Page)

struct MobilityTrackingView: View {
    @StateObject private var viewModel = MobilityTrackingViewModel()
    @State private var selectedActivity: ActivityRecord?

    var body: some View {
        NavigationView {
            ZStack {
                Color.aqua5.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    todaySummaryStrip
                    activitiesList
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            viewModel.requestAuthorization()
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailView(activity: activity, viewModel: viewModel)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mobility Lab")
                        .font(.custom("Avenir-Heavy", size: 28))
                        .foregroundColor(.indigo1)
                    Text(todayDateString)
                        .font(.custom("Avenir", size: 14))
                        .foregroundColor(.charcoal3)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isWatchConnected ? Color.green1 : Color.charcoal3.opacity(0.4))
                        .frame(width: 8, height: 8)
                    Image(systemName: "applewatch")
                        .font(.caption)
                        .foregroundColor(viewModel.isWatchConnected ? .green1 : .charcoal3)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Today Summary Strip

    @ViewBuilder
    private var todaySummaryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                SummaryChip(icon: "figure.walk", value: viewModel.formattedSteps, label: "Steps", color: .indigo1)
                SummaryChip(icon: "heart.fill", value: viewModel.formattedHeartRate, label: "BPM", color: .red1)
                SummaryChip(icon: "flame.fill", value: viewModel.formattedCalories, label: "Cal", color: .tangerine)
                SummaryChip(icon: "point.topleft.down.to.point.bottomright.curvepath", value: viewModel.formattedDistance, label: "km", color: .green1)
                SummaryChip(icon: "lungs.fill", value: viewModel.formattedSpO2, label: "SpO2", color: .cornflower)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Activities List

    @ViewBuilder
    private var activitiesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Activities")
                .font(.custom("Avenir-Heavy", size: 18))
                .foregroundColor(.charcoal1)
                .padding(.horizontal, 16)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.activities) { activity in
                        ActivityListItem(activity: activity)
                            .onTapGesture { selectedActivity = activity }
                    }

                    if viewModel.activities.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.walk.motion")
                                .font(.system(size: 40))
                                .foregroundColor(.charcoal3.opacity(0.4))
                            Text("No activities recorded yet")
                                .font(.custom("Avenir", size: 15))
                                .foregroundColor(.charcoal3)
                            Text("Start an activity on your Apple Watch")
                                .font(.custom("Avenir", size: 13))
                                .foregroundColor(.charcoal3.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Helpers

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Summary Chip

struct SummaryChip: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.charcoal1)
                .lineLimit(1)
            Text(label)
                .font(.custom("Avenir", size: 10))
                .foregroundColor(.charcoal3)
        }
        .frame(width: 65)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Activity List Item

struct ActivityListItem: View {
    let activity: ActivityRecord

    var body: some View {
        HStack(spacing: 14) {
            // Activity icon
            Circle()
                .fill(activity.color.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: activity.icon)
                        .font(.system(size: 18))
                        .foregroundColor(activity.color)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(activity.title)
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(.charcoal1)
                Text(activity.timeRangeString)
                    .font(.custom("Avenir", size: 12))
                    .foregroundColor(.charcoal3)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(activity.formattedDuration)
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(.charcoal1)
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 10))
                        .foregroundColor(.charcoal3)
                    Text(activity.formattedSteps)
                        .font(.custom("Avenir", size: 12))
                        .foregroundColor(.charcoal3)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.charcoal3.opacity(0.5))
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Activity Record Model

struct ActivityRecord: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let startTime: Date
    let endTime: Date
    let steps: Double
    let distance: Double       // meters
    let heartRateAvg: Double
    let heartRateMax: Double
    let calories: Double
    let spO2: Double

    var formattedDuration: String {
        let interval = Int(endTime.timeIntervalSince(startTime))
        let hours = interval / 3600
        let mins = (interval % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins) min"
    }

    var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: steps)) ?? "0"
    }

    var timeRangeString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return "\(fmt.string(from: startTime)) - \(fmt.string(from: endTime))"
    }

    var formattedDistance: String {
        String(format: "%.2f km", distance / 1000.0)
    }

    var formattedCalories: String {
        String(format: "%.0f kcal", calories)
    }

    var formattedHeartRateAvg: String {
        heartRateAvg > 0 ? String(format: "%.0f", heartRateAvg) : "--"
    }

    var formattedHeartRateMax: String {
        heartRateMax > 0 ? String(format: "%.0f", heartRateMax) : "--"
    }

    var formattedSpO2: String {
        spO2 > 0 ? String(format: "%.0f%%", spO2) : "--"
    }
}

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    let activity: ActivityRecord
    @ObservedObject var viewModel: MobilityTrackingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.aqua5.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Circle()
                            .fill(activity.color.opacity(0.12))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: activity.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(activity.color)
                            )
                        Text(activity.title)
                            .font(.custom("Avenir-Heavy", size: 22))
                            .foregroundColor(.charcoal1)
                        Text(activity.timeRangeString)
                            .font(.custom("Avenir", size: 14))
                            .foregroundColor(.charcoal3)
                        Text(activity.formattedDuration)
                            .font(.custom("Avenir-Heavy", size: 32))
                            .foregroundColor(.indigo1)
                    }
                    .padding(.top, 8)

                    // Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        MetricCardView(icon: "figure.walk", title: "Steps", value: activity.formattedSteps, color: .indigo1)
                        MetricCardView(icon: "point.topleft.down.to.point.bottomright.curvepath", title: "Distance", value: activity.formattedDistance, color: .green1)
                        MetricCardView(icon: "heart.fill", title: "Avg Heart Rate", value: activity.formattedHeartRateAvg, unit: "bpm", color: .red1)
                        MetricCardView(icon: "heart.circle", title: "Max Heart Rate", value: activity.formattedHeartRateMax, unit: "bpm", color: .vermillion)
                        MetricCardView(icon: "flame.fill", title: "Calories", value: activity.formattedCalories, color: .tangerine)
                        MetricCardView(icon: "lungs.fill", title: "SpO2", value: activity.formattedSpO2, color: .cornflower)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Metric Card (reused)

struct MetricCardView: View {
    let icon: String
    let title: String
    let value: String
    var unit: String = ""
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            Text(title)
                .font(.custom("Avenir", size: 13))
                .foregroundColor(.charcoal3)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.custom("Avenir-Heavy", size: 28))
                    .foregroundColor(.charcoal1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.custom("Avenir", size: 14))
                        .foregroundColor(.charcoal3)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Activity Row (reused in summary)

struct ActivityRowView: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Avenir", size: 15))
                .foregroundColor(.charcoal3)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(.charcoal1)
                Text(unit)
                    .font(.custom("Avenir", size: 13))
                    .foregroundColor(.charcoal3)
            }
        }
    }
}

// MARK: - Preview

struct MobilityTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        MobilityTrackingView()
    }
}
