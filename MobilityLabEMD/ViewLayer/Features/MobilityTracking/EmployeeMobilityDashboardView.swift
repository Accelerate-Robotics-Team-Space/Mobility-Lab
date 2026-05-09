//
//  EmployeeMobilityDashboardView.swift
//  MobilityLabEMD
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct EmployeeMobilityDashboardView: View {
    @StateObject private var viewModel = EmployeeMobilityDashboardViewModel()
    @State private var searchText = ""
    @State private var selectedEmployee: EmployeeHealthData?
    @State private var showList = false

    private var filteredEmployees: [EmployeeHealthData] {
        if searchText.isEmpty {
            return viewModel.employees
        }
        return viewModel.employees.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color(rRed: 240, gGreen: 241, bBlue: 245).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                summaryBar
                if showList {
                    employeeListView
                } else {
                    employeeGridView
                }
            }
        }
        .sheet(item: $selectedEmployee) { employee in
            EmployeeDetailSheet(employee: employee)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Employee Mobility Dashboard")
                    .font(.custom("Avenir-Heavy", size: 24))
                    .foregroundColor(.charcoal1)
                Text("\(viewModel.employees.count) employees tracked")
                    .font(.custom("Avenir", size: 14))
                    .foregroundColor(.charcoal3)
            }
            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.charcoal3)
                TextField("Search employees...", text: $searchText)
                    .font(.custom("Avenir", size: 14))
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(10)
            .frame(maxWidth: 280)

            Button {
                showList.toggle()
            } label: {
                Image(systemName: showList ? "square.grid.2x2" : "list.bullet")
                    .font(.title3)
                    .foregroundColor(.indigo1)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Summary Bar

    @ViewBuilder
    private var summaryBar: some View {
        HStack(spacing: 16) {
            SummaryPill(icon: "figure.walk", label: "Avg Steps", value: viewModel.averageSteps, color: .indigo1)
            SummaryPill(icon: "heart.fill", label: "Avg HR", value: viewModel.averageHeartRate, unit: "bpm", color: .red1)
            SummaryPill(icon: "flame.fill", label: "Avg Calories", value: viewModel.averageCalories, unit: "kcal", color: .tangerine)
            SummaryPill(icon: "applewatch", label: "Connected", value: "\(viewModel.connectedCount)/\(viewModel.employees.count)", color: .green1)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Grid View

    @ViewBuilder
    private var employeeGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
            ], spacing: 16) {
                ForEach(filteredEmployees) { employee in
                    EmployeeCardView(employee: employee)
                        .onTapGesture { selectedEmployee = employee }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - List View

    @ViewBuilder
    private var employeeListView: some View {
        List {
            ForEach(filteredEmployees) { employee in
                EmployeeListRow(employee: employee)
                    .onTapGesture { selectedEmployee = employee }
                    .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Summary Pill

struct SummaryPill: View {
    let icon: String
    let label: String
    let value: String
    var unit: String = ""
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom("Avenir", size: 12))
                    .foregroundColor(.charcoal3)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.charcoal1)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.custom("Avenir", size: 11))
                            .foregroundColor(.charcoal3)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Employee Card (Grid)

struct EmployeeCardView: View {
    let employee: EmployeeHealthData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.indigo1.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(employee.initials)
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(.indigo1)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(employee.name)
                        .font(.custom("Avenir-Heavy", size: 15))
                        .foregroundColor(.charcoal1)
                        .lineLimit(1)
                    Text(employee.department)
                        .font(.custom("Avenir", size: 12))
                        .foregroundColor(.charcoal3)
                }
                Spacer()
                Circle()
                    .fill(employee.isConnected ? Color.green1 : Color.charcoal3.opacity(0.3))
                    .frame(width: 8, height: 8)
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                MiniMetric(icon: "figure.walk", value: employee.formattedSteps, label: "Steps")
                MiniMetric(icon: "heart.fill", value: employee.formattedHeartRate, label: "HR")
                MiniMetric(icon: "point.topleft.down.to.point.bottomright.curvepath", value: employee.formattedDistance, label: "km")
                MiniMetric(icon: "lungs.fill", value: employee.formattedSpO2, label: "SpO2")
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Mini Metric

struct MiniMetric: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.charcoal3)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(.charcoal1)
                Text(label)
                    .font(.custom("Avenir", size: 10))
                    .foregroundColor(.charcoal3)
            }
        }
    }
}

// MARK: - Employee List Row

struct EmployeeListRow: View {
    let employee: EmployeeHealthData

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.indigo1.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(employee.initials)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(.indigo1)
                )
            VStack(alignment: .leading) {
                Text(employee.name)
                    .font(.custom("Avenir-Heavy", size: 15))
                    .foregroundColor(.charcoal1)
                Text(employee.department)
                    .font(.custom("Avenir", size: 12))
                    .foregroundColor(.charcoal3)
            }
            Spacer()
            HStack(spacing: 24) {
                metricColumn("figure.walk", employee.formattedSteps, "Steps")
                metricColumn("heart.fill", employee.formattedHeartRate, "HR")
                metricColumn("point.topleft.down.to.point.bottomright.curvepath", employee.formattedDistance, "km")
                metricColumn("lungs.fill", employee.formattedSpO2, "SpO2")
                metricColumn("flame.fill", employee.formattedCalories, "kcal")
            }
            Circle()
                .fill(employee.isConnected ? Color.green1 : Color.charcoal3.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func metricColumn(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.charcoal3)
            Text(value)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.charcoal1)
            Text(label)
                .font(.custom("Avenir", size: 10))
                .foregroundColor(.charcoal3)
        }
        .frame(width: 55)
    }
}

// MARK: - Employee Detail Sheet

struct EmployeeDetailSheet: View {
    let employee: EmployeeHealthData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.indigo1.opacity(0.15))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(employee.initials)
                                    .font(.custom("Avenir-Heavy", size: 24))
                                    .foregroundColor(.indigo1)
                            )
                        Text(employee.name)
                            .font(.custom("Avenir-Heavy", size: 22))
                            .foregroundColor(.charcoal1)
                        Text(employee.department)
                            .font(.custom("Avenir", size: 14))
                            .foregroundColor(.charcoal3)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(employee.isConnected ? Color.green1 : Color.charcoal3.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Text(employee.isConnected ? "Watch Connected" : "Watch Disconnected")
                                .font(.custom("Avenir", size: 13))
                                .foregroundColor(employee.isConnected ? .green1 : .charcoal3)
                        }
                    }
                    .padding(.top, 16)

                    // Metrics grid
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        DetailMetricCard(icon: "figure.walk", title: "Steps", value: employee.formattedSteps, color: .indigo1)
                        DetailMetricCard(icon: "point.topleft.down.to.point.bottomright.curvepath", title: "Distance", value: employee.formattedDistance, unit: "km", color: .green1)
                        DetailMetricCard(icon: "heart.fill", title: "Heart Rate", value: employee.formattedHeartRate, unit: "bpm", color: .red1)
                        DetailMetricCard(icon: "lungs.fill", title: "SpO2", value: employee.formattedSpO2, unit: "%", color: .cornflower)
                        DetailMetricCard(icon: "flame.fill", title: "Calories", value: employee.formattedCalories, unit: "kcal", color: .tangerine)
                        DetailMetricCard(icon: "clock.fill", title: "Active Min", value: employee.formattedActiveMinutes, unit: "min", color: .indigo2)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(rRed: 240, gGreen: 241, bBlue: 245))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Detail Metric Card

struct DetailMetricCard: View {
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
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

struct EmployeeMobilityDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        EmployeeMobilityDashboardView()
            .previewDevice(PreviewDevice(rawValue: "iPad Air (5th generation)"))
    }
}
