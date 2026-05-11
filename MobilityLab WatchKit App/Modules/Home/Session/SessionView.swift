//
//  SessionView.swift
//  MobilityLab WatchKit Extension
//
//  Created by Josh Franco on 11/2/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SessionView: View {
    @ObservedObject private var driver: SessionDriver
    @Binding var showSessionFlow: Bool
    @State private var isShowingAlert = false
    @State private var isShowingInfo = false
    
    @Environment(\.scenePhase)
    var scenePhase

    private var isSensingStr: String {
        if driver.isSensing {
            return R.string.localizable.monitoring()
        } else {
            return R.string.localizable.paused()
        }
    }
    private let minTextSize: CGFloat = 0.2
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                Button(action: {
                    withAnimation {
                        driver.isSensing.toggle()
                        
                        if !driver.isSensing {
                            isShowingAlert.toggle()
                            WKInterfaceDevice.current().play(.stop)
                        } else {
                            WKInterfaceDevice.current().play(.start)
                        }
                    }
                }, label: {
                    Text(isSensingStr)
                        .multilineTextAlignment(.center)
                        .textStyle(.header3, color: .white)
                        .frame(maxWidth: .infinity,
                               maxHeight: .infinity)
                        .background(driver.isSensing ? Color.grass : Color.indigo1)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                })
                .blur(radius: isShowingAlert ? 1.5 : 0)
            }
            .allowsHitTesting(false)
            .toast(message: "\(driver.getBuildInfoStr())",
                   isShowing: $isShowingInfo,
                   duration: Toast.short)
            
            if isShowingAlert {
                VStack {
                    Button(action: {
                        driver.tearDown()
                        showSessionFlow.toggle()
                    }, label: {
                        Text(R.string.localizable.end())
                            .textStyle(.header3)
                            .frame(maxWidth: .infinity,
                                   maxHeight: .infinity)
                            .background(Color.vermillion)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    })
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isShowingAlert.toggle()
                        }
                    }, label: {
                        Text(R.string.localizable.continue())
                            .textStyle(.header3)
                            .frame(maxWidth: .infinity)
                            .background(Color.grass)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    })
                }
                .padding()
            }
            Button(action: {
                isShowingInfo.toggle()
            }, label: {
                Image(systemName: "info.circle")
            })
            .frame(width: 8, height: 8)
            .offset(x: 12, y: 12)
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .buttonStyle(PlainButtonStyle())
        .onAppear(perform: driver.onAppear)
        .onReceive(driver.$endSession) { endSession in
            if endSession {
                showSessionFlow = false
            }
        }
    }
    
    // MARK: - Init
    init(_ showSessionFlow: Binding<Bool>, using connectionDriver: BLEConnectionDriver) {
        driver = SessionDriver(connectionDriver: connectionDriver)
        _showSessionFlow = showSessionFlow
    }
    
    fileprivate init() {
        self._showSessionFlow = .constant(true)
        self.driver = SessionDriver()
    }
}

// MARK: - Preview
struct WatchDataFeedView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView()
    }
}
