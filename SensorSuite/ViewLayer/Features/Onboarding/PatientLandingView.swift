//
//  PatientLandingView.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/13/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct PatientLandingView: View {
    @Injected(\.userDefaults) private var userDefaults

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                MobilityTrackingView()

                Text(DeviceConstants.getBuildInfoStr(facilityName: userDefaults.facilityName))
                    .textStyle(.overline, color: .silver)
                    .multilineTextAlignment(.center)
                    .frame(width: geo.size.width)
            }
        }
    }

    // MARK: - Init
    init(_ manager: PatientManagerProtocol? = nil) { }
}

// MARK: - Preview
struct PatientLandingView_Previews: PreviewProvider {
    static var previews: some View {
        PatientLandingView()
    }
}
