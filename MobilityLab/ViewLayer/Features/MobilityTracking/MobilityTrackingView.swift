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
    @State private var selectedTab = 0
    @State private var showExportSheet = false
    @State private var selectedDashboardActivity: ActivityRecord?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationView {
                ZStack {
                    Color.aqua5.ignoresSafeArea()
                    VStack(spacing: 0) {
                        header
                        todaySummaryStrip
                        todayActivitiesList
                    }
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showExportSheet) {
                    ExportActivitiesSheet(viewModel: viewModel)
                }
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Image(systemName: "heart.text.square")
                Text("Dashboard")
            }
            .tag(0)

            // Activities Tab
            NavigationView {
                ZStack {
                    Color.aqua5.ignoresSafeArea()
                    VStack(spacing: 0) {
                        activitiesHeader
                        WorkoutHistoryView(viewModel: viewModel)
                    }
                }
                .navigationBarHidden(true)
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Image(systemName: "figure.walk")
                Text("Activities")
            }
            .tag(1)
        }
        .accentColor(.indigo1)
        .onAppear {
            viewModel.requestAuthorization()
        }
    }

    // MARK: - Activities Header

    @ViewBuilder
    private var activitiesHeader: some View {
        HStack {
            Text("Activities")
                .font(.custom("Avenir-Heavy", size: 28))
                .foregroundColor(.indigo1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
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
                    if !viewModel.wearLocation.isEmpty && viewModel.isWatchConnected {
                        Text("·")
                            .foregroundColor(.charcoal3)
                        Image(systemName: "sensor.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.indigo1)
                        Text(viewModel.wearLocation.capitalized)
                            .font(.custom("Avenir", size: 11))
                            .foregroundColor(.charcoal3)
                    }
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
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]
        LazyVGrid(columns: columns, spacing: 12) {
            SummaryChip(icon: "figure.walk", value: viewModel.formattedSteps, label: "Steps", color: .indigo1)
            SummaryChip(icon: "heart.fill", value: viewModel.formattedHeartRate, label: "BPM", color: .red1)
            SummaryChip(icon: "flame.fill", value: viewModel.formattedCalories, label: "Cal", color: .tangerine)
            SummaryChip(icon: "point.topleft.down.to.point.bottomright.curvepath", value: viewModel.formattedDistance, label: "km", color: .green1)
            SummaryChip(icon: "figure.stairs", value: viewModel.formattedFloors, label: "Floors", color: .tangerine)
            SummaryChip(icon: "lungs.fill", value: viewModel.formattedSpO2, label: "SpO2", color: .cornflower)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Today's Activities (Dashboard)

    @ViewBuilder
    private var todayActivitiesList: some View {
        if viewModel.activities.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 36))
                    .foregroundColor(.charcoal3.opacity(0.4))
                Text("No activities yet today")
                    .font(.custom("Avenir", size: 15))
                    .foregroundColor(.charcoal3)
                Button {
                    showExportSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13))
                        Text("Export Past Activities")
                            .font(.custom("Avenir", size: 13))
                    }
                    .foregroundColor(.indigo1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.indigo1.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 4) {
                    HStack {
                        Text("Today's Activities")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(.charcoal1)
                        Spacer()
                        Button {
                            showExportSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 12))
                                Text("Export")
                                    .font(.custom("Avenir", size: 12))
                            }
                            .foregroundColor(.indigo1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.indigo1.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.activities.reversed()) { activity in
                            ActivityListItem(activity: activity)
                                .onTapGesture {
                                    selectedDashboardActivity = activity
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .sheet(item: $selectedDashboardActivity) { activity in
                ActivityDetailView(activity: activity, viewModel: viewModel)
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
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.custom("Avenir-Heavy", size: 22))
                .foregroundColor(.charcoal1)
                .lineLimit(1)
            Text(label)
                .font(.custom("Avenir", size: 12))
                .foregroundColor(.charcoal3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(14)
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

// MARK: - Activity Classification

enum ActivityClassification: String {
    case lightWalk = "light_walk"
    case briskWalk = "brisk_walk"
    case stairClimbing = "stair_climbing"
    case running = "running"
    case activity = "activity"

    var title: String {
        switch self {
        case .lightWalk: return "Light Walk"
        case .briskWalk: return "Brisk Walk"
        case .stairClimbing: return "Stair Climb"
        case .running: return "Run"
        case .activity: return "Activity"
        }
    }

    var icon: String {
        switch self {
        case .lightWalk: return "figure.walk"
        case .briskWalk: return "figure.walk.motion"
        case .stairClimbing: return "figure.stairs"
        case .running: return "figure.run"
        case .activity: return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .lightWalk: return .indigo1
        case .briskWalk: return .green1
        case .stairClimbing: return .tangerine
        case .running: return .vermillion
        case .activity: return .indigo1
        }
    }

    /// Classify an activity based on heart rate, cadence, flights climbed, and speed.
    /// Uses HR zones (220 - age), cadence thresholds, and altitude gain.
    static func classify(
        heartRateAvg: Double,
        cadence: Double,
        flightsClimbed: Double,
        durationSeconds: Double,
        distance: Double,
        age: Int = 40,
        wearLocation: String = ""
    ) -> ActivityClassification {
        let maxHR = Double(220 - age)
        let hrPercent = heartRateAvg > 0 ? (heartRateAvg / maxHR) * 100 : 0
        let speedMph = durationSeconds > 0
            ? (distance / 1609.34) / (durationSeconds / 3600) : 0

        // Stair climbing: flights > 0 with active stepping
        if flightsClimbed >= 1 && cadence >= 40 {
            return .stairClimbing
        }

        // Stair climbing heuristic: high cadence but very low speed
        // (stairs produce many steps with minimal horizontal distance)
        if cadence >= 80 && speedMph < 2.5 && durationSeconds > 30 {
            return .stairClimbing
        }

        // Chest placement heuristic: moderate+ cadence with low speed
        // is likely stair climbing in clinical mobility assessments
        if wearLocation == "chest" && cadence >= 60 && speedMph < 3.0 {
            return .stairClimbing
        }

        // Running: high cadence OR high speed with elevated HR
        if cadence >= 150 || (speedMph > 5.0 && hrPercent > 70) {
            return .running
        }

        // Brisk walk: moderate cadence OR moderate speed with some HR elevation
        if cadence >= 100 || (speedMph > 3.3 && hrPercent > 55) {
            return .briskWalk
        }

        return .lightWalk
    }

    static func from(activityType: String) -> ActivityClassification {
        ActivityClassification(rawValue: activityType) ?? .activity
    }
}

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
    let flightsClimbed: Double
    let cadence: Double        // steps per minute
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

    var formattedFlightsClimbed: String {
        flightsClimbed > 0 ? String(format: "%.0f", flightsClimbed) : "0"
    }

    var formattedCadence: String {
        cadence > 0 ? String(format: "%.0f", cadence) : "--"
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
                        MetricCardView(
                            icon: "point.topleft.down.to.point.bottomright.curvepath",
                            title: "Distance", value: activity.formattedDistance, color: .green1
                        )
                        MetricCardView(icon: "heart.fill", title: "Avg Heart Rate", value: activity.formattedHeartRateAvg, unit: "bpm", color: .red1)
                        MetricCardView(
                            icon: "heart.circle", title: "Max Heart Rate",
                            value: activity.formattedHeartRateMax, unit: "bpm", color: .vermillion
                        )
                        MetricCardView(icon: "flame.fill", title: "Calories", value: activity.formattedCalories, color: .tangerine)
                        MetricCardView(
                            icon: "figure.stairs", title: "Flights Climbed",
                            value: activity.formattedFlightsClimbed, unit: "floors", color: .tangerine
                        )
                        MetricCardView(icon: "metronome", title: "Cadence", value: activity.formattedCadence, unit: "spm", color: .indigo1)
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

// MARK: - Export Activities Sheet

struct ExportActivitiesSheet: View {
    @ObservedObject var viewModel: MobilityTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.aqua5.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Date Range")
                            .font(.custom("Avenir-Heavy", size: 18))
                            .foregroundColor(.charcoal1)

                        DatePicker(
                            "From",
                            selection: $viewModel.exportStartDate,
                            in: ...viewModel.exportEndDate,
                            displayedComponents: .date
                        )
                        .font(.custom("Avenir", size: 15))

                        DatePicker(
                            "To",
                            selection: $viewModel.exportEndDate,
                            in: viewModel.exportStartDate...Date(),
                            displayedComponents: .date
                        )
                        .font(.custom("Avenir", size: 15))
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(
                        color: Color.black.opacity(0.06),
                        radius: 4, x: 0, y: 2
                    )

                    Button {
                        viewModel.exportActivitiesCSV()
                    } label: {
                        HStack {
                            if viewModel.isExporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text("Export CSV")
                                .font(.custom("Avenir-Heavy", size: 16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.indigo1)
                        .cornerRadius(14)
                    }
                    .disabled(viewModel.isExporting)

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Export Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: viewModel.exportCSVURL) { url in
                if url != nil { showShareSheet = true }
            }
            .sheet(isPresented: $showShareSheet, onDismiss: {
                viewModel.exportCSVURL = nil
            }) {
                if let url = viewModel.exportCSVURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
}

// MARK: - Share Sheet (UIKit wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

// MARK: - Preview

struct MobilityTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        MobilityTrackingView()
    }
}
