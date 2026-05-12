//
//  HomeView.swift
//  MobilityLab WatchKit Extension
//
//  Created by Josh Franco on 8/11/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var devMenuSensorDriver: DevSensorDriver
    @ObservedObject var driver = HomeDriver()

    @State private var showActivity = false
    @State private var selectedPlacement: WearLocation = .wrist

    private let btnRad: CGFloat = 17
    private let minTextSize: CGFloat = 0.2

    var body: some View {
        if showActivity {
            ActivitySessionView(isActive: $showActivity, placement: selectedPlacement)
        } else {
            ScrollView {
                VStack(spacing: 8) {
                    Text("Where is the Watch?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    // Placement selection
                    ForEach(placementOptions, id: \.location) { option in
                        Button {
                            selectedPlacement = option.location
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 14))
                                Text(option.label)
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                if selectedPlacement == option.location {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                }
                            }
                            .foregroundColor(selectedPlacement == option.location ? .white : .gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedPlacement == option.location ? Color.indigo1.opacity(0.6) : Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }

                    // Start Activity
                    Button {
                        showActivity = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 22))
                            Text("Start Activity")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.indigo1)
                        .cornerRadius(btnRad)
                    }
                    .buttonStyle(WearableButtonStyle())
                    .padding(.top, 4)

                    if [.dev, .qa, .test].contains(ALTEnvironment.current) {
                        NavigationLink(
                            destination: DevMenuView()
                                .environmentObject(devMenuSensorDriver),
                            label: {
                                HStack {
                                    Text("Dev Menu")
                                        .textStyle(.bold, color: .indigo1)
                                    Image(systemName: "ant")
                                        .foregroundColor(.indigo1)
                                }
                                .padding()
                                .background(Color.columbiaBlue)
                                .cornerRadius(btnRad)
                            })
                        .buttonStyle(WearableButtonStyle())
                    }

                    Text(driver.getBuildInfoStr())
                        .textStyle(.overline, color: .silver)
                        .lineLimit(1)
                        .minimumScaleFactor(minTextSize)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Placement Options

    private var placementOptions: [(location: WearLocation, icon: String, label: String)] {
        [
            (.wrist, "applewatch", "Wrist"),
            (.chest, "heart.fill", "Chest"),
            (.ankle, "figure.walk", "Ankle / Foot"),
        ]
    }
}

struct WatchLandingView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 17.0, *) {
            NavigationStack {
                HomeView()
                    .environmentObject(DevSensorDriver())
            }
        } else {
            NavigationView {
                HomeView()
                    .environmentObject(DevSensorDriver())
            }
        }
    }
}
