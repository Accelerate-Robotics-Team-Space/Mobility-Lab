//
//  EnrollmentView.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct EnrollmentView: View {
    @Binding var modalFlow: DeviceRegistrationLandingDriver.ActiveModal?
    @StateObject var enrollmentDriver: EnrollmentDriver
    @EnvironmentObject var deviceRegistrationLandingDriver: DeviceRegistrationLandingDriver
    
    @State var fromLandingView: Bool
    
    private let indicatorOffset: CGFloat = 65
    private let indicatorLineWidth: CGFloat = 8
    private let cornerRad: CGFloat = 7.5
    
    // MARK: - Computed Variables
    private var isDevEnv: Bool {
        ALTEnvironment.current == .dev || ALTEnvironment.current == .qa
    }
    
    private var alert: Alert {
        let (title, msg) = enrollmentDriver.alertInfo
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
                Color.charcoal3
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.30)
                    .mask(SquareHoleShape(holeSize: geo.size.width - indicatorOffset))
                
                CodeScannerView(codeTypes: [.qr],
                                useFrontCamera: UserDefaults.standard.useFrontCamera,
                                completion: enrollmentDriver.scanHandler(result:))
                VStack {
                    Text(R.string.localizable.scanQRCode())
                        .frame(width: 133, height: 27)
                        .font(.custom("SF Compact Text", size: 16))
                        .foregroundColor(.charcoal3)
                        .background(Color.white)
                        .cornerRadius(12.13)
                        .padding()
                    
                    Spacer()
                    
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
                
                SquareIndicatorShape(indicatorLength: 45)
                    .stroke(style: StrokeStyle(lineWidth: indicatorLineWidth,
                                               lineJoin: .round))
                    .foregroundColor(.white)
                    .frame(
                        width: (geo.size.width - indicatorOffset).clamp(),
                        height: (geo.size.width - indicatorOffset).clamp()
                    )
                if enrollmentDriver.isLoading {
                    BarLoadingView(barColor: .vermillion)
                }
            }
        }
        .onReceive(enrollmentDriver.$deviceValidatedAndRegistered) { deviceValidatedAndRegistered in
            guard let deviceValidatedAndRegistered = deviceValidatedAndRegistered else { return }
            if deviceValidatedAndRegistered {
                if fromLandingView {
                    deviceRegistrationLandingDriver.currentScreen = .dashboard
                }
                dismiss()
            }
        }
        .alert(isPresented: $enrollmentDriver.showAlert, content: { alert })
        .navigationBarHidden(true)
    }
    
    // MARK: - Init
    fileprivate init() {
        self._modalFlow = .constant(nil)
        self._enrollmentDriver = StateObject(wrappedValue: EnrollmentDriver(.device))
        self.fromLandingView = false
    }
    
    init(_ modalFlow: Binding<DeviceRegistrationLandingDriver.ActiveModal?>) {
        self._modalFlow = modalFlow
        self._enrollmentDriver = StateObject(wrappedValue: EnrollmentDriver(.device))
        self.fromLandingView = true
    }
}

// MARK: - Private
private extension EnrollmentView {
    func dismiss() {
        self.modalFlow = nil
    }
}

// MARK: - Preview
struct EnrollmentView_Previews: PreviewProvider {
    static var previews: some View {
        EnrollmentView()
    }
}
