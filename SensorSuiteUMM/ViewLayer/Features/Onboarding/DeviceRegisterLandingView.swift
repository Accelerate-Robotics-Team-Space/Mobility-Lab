//
//  DeviceRegisterLandingView.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/12/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DeviceRegisterLandingView: View {
    @StateObject var deviceRegisterLandingDriver = DeviceRegistrationLandingDriver()
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                VStack {
                    if deviceRegisterLandingDriver.currentScreen == .landing {
                        DeviceHomeView(deviceRegistrationLandingDriver: deviceRegisterLandingDriver)
                    } else if deviceRegisterLandingDriver.currentScreen == .dashboard {
                        DashboardView()
                            .environmentObject(deviceRegisterLandingDriver)
                            .refreshable {
                                DispatchQueue.main.async {
                                    if let scene = UIApplication.shared.connectedScenes.first,
                                       let sceneDelegate: SceneDelegate = (scene.delegate as? SceneDelegate) {
                                        sceneDelegate.resetRootController(scene: scene)
                                    }
                                }
                            }
                    }
                }
                VStack {
                    Text(DeviceConstants.getUMMBuildInfoStr())
                        .textStyle(.overline, color: .silver)
                        .multilineTextAlignment(.center)
                }
                .frame(width: geo.size.width)
                .background(deviceRegisterLandingDriver.currentScreen.backgroundColor)
            }
        }
        .fullScreenCover(
            item: $deviceRegisterLandingDriver.modal,
            onDismiss: { }
        ) { item in
            if item == .registerDevice {
                ZStack(alignment: .bottom) {
                    EnrollmentView($deviceRegisterLandingDriver.modal)
                        .environmentObject(deviceRegisterLandingDriver)
                    Text(DeviceConstants.getUMMBuildInfoStr())
                        .textStyle(.overline, color: .silver)
                        .multilineTextAlignment(.center)
                }
            } else if item == .devMenu {
                DevMenuView($deviceRegisterLandingDriver.modal)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct DeviceRegisterLandingView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceRegisterLandingView()
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPadAirUMM()))
    }
}
