//
//  EnrollmentView.swift
//  SensorSuite
//
//  Created by Josh Franco on 3/9/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct EnrollmentView: View {
    @Binding var modalFlow: PatientLandingDriver.ActiveModal?
    @Binding var pairWearablesFlow: DashboardDriver.PairWearablesModal?
    @ObservedObject var driver: EnrollmentDriver
    @EnvironmentObject var patientLandingDriver: PatientLandingDriver
    
    @State var fromLandingView: Bool
    
    private let indicatorOffset: CGFloat = 65
    private let indicatorLineWidth: CGFloat = 8
    private let cornerRad: CGFloat = 7.5
    
    // MARK: - Computed Variables
    private var isDevEnv: Bool {
        ALTEnvironment.current == .dev || ALTEnvironment.current == .qa
    }
    
    private var alert: Alert {
        let (title, msg) = driver.alertInfo
        let alertAction = {
            dismiss()
        }
        
        return Alert(title: Text(title),
                     message: Text(msg),
                     dismissButton: .default(R.string.localizable.ok.text,
                                             action: alertAction))
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
                CodeScannerView(
                    codeTypes: [.qr],
                    useFrontCamera: isDevEnv ? false : true,
                    completion: driver.scanHandler(result:)
                )

                Color.charcoal3
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.30)
                    .mask(SquareHoleShape(holeSize: geo.size.width - indicatorOffset - indicatorLineWidth))

                SquareIndicatorShape(indicatorLength: 45)
                    .stroke(style: StrokeStyle(lineWidth: indicatorLineWidth, lineJoin: .round))
                    .foregroundColor(.white)
                    .frame(width: geo.size.width - indicatorOffset,
                           height: geo.size.width - indicatorOffset)
                
                if driver.isLoading {
                    BarLoadingView(barColor: .vermillion)
                }
            }
        }
        .onReceive(driver.$deviceValidatedAndRegistered) { deviceValidatedAndRegistered in
            guard let deviceValidatedAndRegistered = deviceValidatedAndRegistered else { return }
            if deviceValidatedAndRegistered {
                if fromLandingView {
                    patientLandingDriver.currentScreen = .greet
                }
                dismiss()
            }
        }
        .onReceive(driver.$wearableRegistered) { wearableRegistered in
            guard let wearableRegistered = wearableRegistered else { return }
            if wearableRegistered { dismiss() }
        }
        .alert(isPresented: $driver.showAlert, content: { alert })
        .edgesIgnoringSafeArea(.all)
        .safeAreaInset(edge: .top) {
            Text(R.string.localizable.scanQRCode())
                .frame(width: 133, height: 27)
                .font(.custom("SF Compact Text", size: 16))
                .foregroundColor(.charcoal3)
                .background(Color.white)
                .cornerRadius(12.13)
                .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                dismiss()
            }, label: {
                R.string.localizable.cancel.text
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .font(.custom("Avenir", size: 16))
                    .foregroundColor(.black)
            })
            .padding(.all, 12)
            .background(Color.white)
            .cornerRadius(2000)
            .frame(minWidth: 44, minHeight: 44)
            .padding()
        }
    }
    
    // MARK: - Init
    fileprivate init() {
        self._modalFlow = .constant(nil)
        self._pairWearablesFlow = .constant(nil)
        self.driver = EnrollmentDriver()
        self.fromLandingView = false
    }
    
    init(_ modalFlow: Binding<PatientLandingDriver.ActiveModal?>) {
        self._modalFlow = modalFlow
        self._pairWearablesFlow = .constant(nil)
        self.driver = EnrollmentDriver()
        self.fromLandingView = true
    }
}

// MARK: - Private
private extension EnrollmentView {
    func dismiss() {
        self.modalFlow = nil
        self.pairWearablesFlow = nil
    }
}

// MARK: Preview
struct EnrollmentView_Previews: PreviewProvider {
    static var previews: some View {
        EnrollmentView()
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
