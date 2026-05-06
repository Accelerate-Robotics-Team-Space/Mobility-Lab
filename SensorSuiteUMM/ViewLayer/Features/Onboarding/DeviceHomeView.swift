//
//  DeviceHomeView.swift
//  SensorSuiteUMM
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
        if deviceRegistrationLandingDriver.isRegistered {
            DashboardView()
                .environmentObject(deviceRegistrationLandingDriver)
        } else {
            GeometryReader { geo in
                VStack {
                    Spacer(minLength: 20)

                    VStack(spacing: 0) {
                        Image(R.image.atlasLiftBanner.name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.50)
                            .onTapGesture(count: 5) {
                                fatalError("User generated Crash")
                            }
                        Text(R.string.localizable.enhancingPatientSafety())
                            .font(.custom("Avenir-Roman", size: 16))
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)
                            .foregroundColor(Color.charcoal3)
                        
                        ZStack(alignment: .bottom) {
                            VStack {}
                                .frame(width: geo.size.width, height: 122)
                                .background(Color.lightAqua)
                            
                            Image(R.image.patientLandingBackground.name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width)

                            VStack {
                                HStack {
                                    Button(action: {
                                        deviceRegistrationLandingDriver.modal = .registerDevice
                                    }, label: {
                                        Text(R.string.localizable.registerDevice())
                                            .frame(maxWidth: .infinity)
                                    })
                                    .flatBtnStyle()
                                    
                                    if deviceRegistrationLandingDriver.isDevMode {
                                        Button(action: {
                                            deviceRegistrationLandingDriver.modal = .devMenu
                                        }, label: {
                                            Image(systemName: "ant")
                                                .frame(width: 40)
                                        })
                                        .flatBtnStyle()
                                    }
                                }
                                
                                Button(action: {
                                    securityService.resetDeviceRegistered()
                                }, label: {
                                    Text(R.string.localizable.admin())
                                        .frame(maxWidth: .infinity)
                                        .font(Font.headline.bold())
                                })
                                .buttonStyle(FlatButtonStyle(.clear()))
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
        }
    }
}

struct DeviceHomeView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceHomeView(deviceRegistrationLandingDriver: DeviceRegistrationLandingDriver())
    }
}
