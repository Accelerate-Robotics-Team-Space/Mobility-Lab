//
//  DeviceHomeView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/19/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct DeviceHomeView: View {
    @Injected(\.securityService) 
    private var securityService
    @ObservedObject var deviceRegistrationLandingDriver: DeviceRegistrationLandingDriver
    
    @State var toggle = true
    
    var body: some View {
        EmployeeMobilityDashboardView()
    }
}

struct DeviceHomeView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceHomeView(deviceRegistrationLandingDriver: DeviceRegistrationLandingDriver())
    }
}
