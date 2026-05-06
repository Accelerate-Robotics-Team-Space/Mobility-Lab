//
//  ScanView.swift
//  SensorSuite WatchKit Extension
//
//  Created by Josh Franco on 3/5/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ScanView: View {
    @ObservedObject var driver: ScanDriver
    @Binding var showScanView: Bool

    private let infoBtnSize: CGFloat = 44
    private let btnRad: CGFloat = 17
    private let minTextSize: CGFloat = 0.2
    
    private var wearableId: String {
        UserDefaults.standard.wearableId.formattedId()
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(R.string.localizable.wearableId() + ":")
                        .textStyle(.caption, color: .ash)
                        .minimumScaleFactor(minTextSize)
                    
                    Text(wearableId)
                        .textStyle(.header5, color: .ash)
                        .minimumScaleFactor(minTextSize)
                }
                
                HStack(spacing: 0) {
                    Spacer()
                    
                    ProgressView()
                        .frame(width: infoBtnSize,
                               height: infoBtnSize)
                    
                    Spacer()
                    
                    R.string.localizable.basestationScanning.text
                        .textStyle(.body2, color: .ash)
                        .minimumScaleFactor(minTextSize)
                }
                
                Spacer()
                
                Button(action: {
                    driver.cancelScan()
                    showScanView = false
                }, label: {
                    HStack {
                        R.string.localizable.cancelScan.text
                            .textStyle(.bold, color: .ash)
                    }
                    .frame(maxWidth: .infinity)
                })
                .buttonStyle(WearableButtonStyle())
                .buttonStyle(PlainButtonStyle())
                .frame(height: infoBtnSize)
                .background(Color.indigo1)
                .cornerRadius(btnRad)
            }
        }
        .onAppear(perform: {
            driver.startScan()
            driver.dismissView {
                showScanView = false
            }
        })
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Init
    init(_ showView: Binding<Bool>, driver: ScanDriver) {
        self.driver = driver
        self._showScanView = showView
    }
}
