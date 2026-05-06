//
//  PatientGreetView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 9/15/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientGreetView: View {
    private let cornerRad: CGFloat = 16
    private let outlineWidth: CGFloat = 1
    @State private var showPanel = true
    @ObservedObject var driver: PatientLandingDriver
    
    // MARK: - Body
    var body: some View {
        ZStack (alignment: .bottom) {
            Color.indigoBkgd.ignoresSafeArea()

            VStack {
                Spacer()
                ZStack {
                    Image(R.image.heart.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 44)
                        .padding(.vertical, 20)

                    VStack {
                        if showPanel {
                            VStack (alignment: .leading) {
                                Text(R.string.localizable.deviceRegisterSuccessfully())
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.charcoal1)
                                Text(R.string.localizable.patientGreet())
                                    .font(.custom("Avenir-Roman", size: 14))
                                    .foregroundColor(.charcoal1)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(cornerRad)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showPanel.toggle()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                VStack {
                    Text(R.string.localizable.helpEliminateDeaths())
                        .textStyle(.header2, color: .white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 43)

                    Spacer()

                    R.image.greetingNurse.image
                        .resizable()
                        .scaledToFit()
                }

                VStack (spacing: 16) {
                    Button(action: {
                        withAnimation {
                            driver.currentScreen = .landing
                        }
                    }, label: {
                        Text(R.string.localizable.continue())
                            .frame(maxWidth: .infinity)
                    })
                    .altBtnPlainWhite()
                    .padding(.horizontal)
                    .padding(.vertical)
                }
            }
        }
    }
}

struct PatientGreetView_Previews: PreviewProvider {
    static var previews: some View {
        PatientGreetView(driver: PatientLandingDriver())
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
