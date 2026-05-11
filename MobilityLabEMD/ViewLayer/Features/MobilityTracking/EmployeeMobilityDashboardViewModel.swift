//
//  EmployeeMobilityDashboardViewModel.swift
//  MobilityLabEMD
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation

final class EmployeeMobilityDashboardViewModel: ObservableObject {
    @Published var employees: [EmployeeHealthData] = []

    @Injected(\.phoneConnectivityService) private var connectivityService

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Computed Summaries

    var averageSteps: String {
        guard !employees.isEmpty else { return "0" }
        let avg = employees.map(\.steps).reduce(0, +) / Double(employees.count)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: avg)) ?? "0"
    }

    var averageHeartRate: String {
        let active = employees.filter { $0.heartRate > 0 }
        guard !active.isEmpty else { return "--" }
        let avg = active.map(\.heartRate).reduce(0, +) / Double(active.count)
        return String(format: "%.0f", avg)
    }

    var averageCalories: String {
        guard !employees.isEmpty else { return "0" }
        let avg = employees.map(\.calories).reduce(0, +) / Double(employees.count)
        return String(format: "%.0f", avg)
    }

    var connectedCount: Int {
        employees.filter(\.isConnected).count
    }

    // MARK: - Init

    init() {
        loadSampleEmployees()
        subscribeToUpdates()
    }

    // MARK: - Watch Data

    private func subscribeToUpdates() {
        connectivityService.activate()

        connectivityService.healthDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.handleIncomingData(data)
            }
            .store(in: &cancellables)
    }

    private func handleIncomingData(_ data: [String: Any]) {
        guard let employeeId = data["employeeId"] as? String else { return }

        if let index = employees.firstIndex(where: { $0.id == employeeId }) {
            if let val = data["stepCount"] as? Double { employees[index].steps = val }
            if let val = data["heartRate"] as? Double { employees[index].heartRate = val }
            if let val = data["distance"] as? Double { employees[index].distance = val }
            if let val = data["activeCalories"] as? Double { employees[index].calories = val }
            employees[index].isConnected = true
            employees[index].lastUpdated = Date()
        }
    }

    // MARK: - Sample Data

    private func loadSampleEmployees() {
        employees = [
            EmployeeHealthData(id: "emp-001", name: "Sarah Johnson", department: "Nursing", steps: 8420, distance: 5200, heartRate: 72, spO2: 98, calories: 340, activeMinutes: 45, isConnected: true),
            EmployeeHealthData(id: "emp-002", name: "Marcus Chen", department: "Physical Therapy", steps: 12350, distance: 8100, heartRate: 68, spO2: 99, calories: 520, activeMinutes: 72, isConnected: true),
            EmployeeHealthData(id: "emp-003", name: "Aisha Patel", department: "Nursing", steps: 6780, distance: 4300, heartRate: 76, spO2: 97, calories: 280, activeMinutes: 38, isConnected: true),
            EmployeeHealthData(id: "emp-004", name: "James Wilson", department: "Facilities", steps: 15200, distance: 10400, heartRate: 82, spO2: 98, calories: 680, activeMinutes: 95, isConnected: false),
            EmployeeHealthData(id: "emp-005", name: "Maria Rodriguez", department: "Nursing", steps: 9100, distance: 6000, heartRate: 0, spO2: 0, calories: 390, activeMinutes: 52, isConnected: false),
            EmployeeHealthData(id: "emp-006", name: "David Kim", department: "Physical Therapy", steps: 11000, distance: 7200, heartRate: 70, spO2: 98, calories: 460, activeMinutes: 63, isConnected: true),
        ]
    }
}
