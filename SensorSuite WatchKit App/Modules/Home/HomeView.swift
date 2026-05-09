//
//  HomeView.swift
//  SensorSuite WatchKit Extension
//
//  Created by Josh Franco on 8/11/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var devMenuSensorDriver: DevSensorDriver
    @ObservedObject var driver = HomeDriver()

    @State private var showActivity = false

    private let btnRad: CGFloat = 17
    private let minTextSize: CGFloat = 0.2

    var body: some View {
        if showActivity {
            ActivitySessionView(isActive: $showActivity)
        } else {
            VStack {
                Button(action: {
                    showActivity = true
                }, label: {
                    VStack(spacing: 6) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 28))
                        Text("Start Activity")
                            .textStyle(.bold, color: .ash)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.indigo1)
                    .cornerRadius(btnRad)
                })
                .buttonStyle(WearableButtonStyle())

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
        }
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
