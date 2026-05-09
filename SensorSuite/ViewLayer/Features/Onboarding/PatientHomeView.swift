//
//  PatientHomeView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 11/20/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct PatientHomeView: View {
    @ObservedObject var driver: PatientLandingDriver
    @ObservedObject var audioAlertPlayer: AudioAlertPlayer
    
    @State var toggle: Bool = true
    @State var adminOverride: Bool = false
    @State var isLoading: Bool = false

    @Injected(\.securityService) private var securityService

    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer(minLength: 33)
                
                VStack(spacing: 0) {
                    Spacer()
                    Image(R.image.atlasLiftBanner.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.80)
                        .padding(.top, 36)
                        .onTapGesture(count: 3) {
                            adminOverride.toggle()
                        }
                    Text(R.string.localizable.enhancingPatientSafety())
                        .textStyle(.body, color: .charcoal3)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 250)
                        .padding(.top, 16)
                    Spacer()
                    ZStack(alignment: .bottom) {
                        Image(R.image.patientLandingBackground.name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width)

                        ZStack {
                            VStack {}
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.lightAqua)
                                .padding(.top, 8)

                            VStack(spacing: 16, content: {
                                HStack {
                                    Button(action: {
                                        driver.modal = .newPatient
                                    }, label: {
                                        Text("Start Tracking")
                                            .frame(maxWidth: .infinity)
                                    })
                                    .altBtnIndigo()

                                    if driver.isDevMode {
                                        Button(action: {
                                            driver.modal = .devMenu
                                        }, label: {
                                            Image(systemName: "ant")
                                                .frame(width: 40)
                                        })
                                        .altBtnIndigo()
                                    }
                                }

                                if showAdminButton {
                                    Button(action: {
                                        driver.showAdminPanel.toggle()
                                    }, label: {
                                        Text(R.string.localizable.admin())
                                            .frame(maxWidth: .infinity)
                                    })
                                    .altButtonCustom(textColor: .indigo1, backgroundColor: .aqua5)
                                } else {
                                    Spacer()
                                        .frame(height: 1)
                                }
                            })
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .frame(maxHeight: showAdminButton ? 118 : 70)
                    }
                }
            }
        }
    }

    private var showAdminButton: Bool {
        ALTEnvironment.current != .prod || adminOverride
    }
}

struct PatientHomeView_Previews: PreviewProvider {
    static var previews: some View {
        PatientHomeView(driver: PatientLandingDriver(), audioAlertPlayer: AudioAlertPlayer())
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
