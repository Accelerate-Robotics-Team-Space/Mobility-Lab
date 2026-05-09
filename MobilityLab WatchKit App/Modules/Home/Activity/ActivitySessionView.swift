//
//  ActivitySessionView.swift
//  MobilityLab WatchKit App
//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI
import WatchKit

struct ActivitySessionView: View {
    @Binding var isActive: Bool
    @StateObject private var driver = ActivitySessionDriver()
    @State private var showEndConfirmation = false

    var body: some View {
        ZStack {
            if showEndConfirmation {
                endConfirmationView
            } else {
                activeSessionView
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { driver.startSession() }
    }

    // MARK: - Active Session

    @ViewBuilder
    private var activeSessionView: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Duration
                Text(driver.formattedDuration)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                // Metrics grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    WatchMetricTile(icon: "figure.walk", value: driver.formattedSteps, label: "Steps", color: .indigo1)
                    WatchMetricTile(icon: "heart.fill", value: driver.formattedHeartRate, label: "BPM", color: .red1)
                    WatchMetricTile(icon: "flame.fill", value: driver.formattedCalories, label: "Cal", color: .tangerine)
                    WatchMetricTile(icon: "point.topleft.down.to.point.bottomright.curvepath", value: driver.formattedDistance, label: "km", color: .green1)
                }

                // End button
                Button {
                    showEndConfirmation = true
                    WKInterfaceDevice.current().play(.stop)
                } label: {
                    Text("End Activity")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.vermillion)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - End Confirmation

    @ViewBuilder
    private var endConfirmationView: some View {
        VStack(spacing: 12) {
            Text("End Activity?")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Button {
                driver.stopSession()
                isActive = false
            } label: {
                Text("End")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.vermillion)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Button {
                showEndConfirmation = false
                WKInterfaceDevice.current().play(.start)
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.grass)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

// MARK: - Watch Metric Tile

struct WatchMetricTile: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}
