//
//  DeviceRegisterLandingView.swift
//  MobilityLabEMD
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
                EmployeeMobilityDashboardView()
                VStack {
                    Text(DeviceConstants.getEMDBuildInfoStr())
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
            if item == .devMenu {
                DevMenuView($deviceRegisterLandingDriver.modal)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct DeviceRegisterLandingView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceRegisterLandingView()
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPadAirEMD()))
    }
}
