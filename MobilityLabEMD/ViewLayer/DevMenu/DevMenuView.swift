//
//  DevMenuView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/21/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import SwiftUI

@MainActor
struct DevMenuView: View {
    @Binding var devMenu: DeviceRegistrationLandingDriver.ActiveModal?
    @Injected(\.securityService)  private var securityService
    private var enrollmentDriver = EnrollmentDriver(.device)

    enum Camera: String, CaseIterable {
        case front = "Front"
        case back = "Back"

        var otherCameraText: String {
            "Flip camera to \(self == .back ? "Front" : "Rear")"
        }
    }

    @State private var showDashboard = false
    @State private var isLoading = false
    @State private var showResetAlert = false
    @State private var showResetDatabaseAlert = false
    @State private var showResetAll = false
    @State private var jwtAlert = false
    @State private var jwtToken: String = ""
    @State private var registrationSuccess: Bool?
    @State private var cameraUsed: Camera = UserDefaults.standard.useFrontCamera ? .front : .back

    @State private var cancellables: Set<AnyCancellable> = []

    // MARK: - Computed Variables
    var resetAlert: Alert {
        let resetAction = {
            securityService.resetDeviceRegistered()
            devMenu = nil
        }
        
        return Alert(title: Text("Reset Registration"),
                     message: Text("Are you sure you want to reset your device registration?"),
                     primaryButton: .default(Text("YES!"),
                                             action: resetAction),
                     secondaryButton: .cancel(Text("Cancel")))
    }
    
    var resetDatabaseAlert: Alert {
        let resetAction = {
//            SecurityService.shared.resetTable()
            devMenu = nil
        }
        
        return Alert(title: Text("Truncate Database"),
                     message: Text("Are you sure you want to reset your local database?"),
                     primaryButton: .default(Text("YES!"),
                                             action: resetAction),
                     secondaryButton: .cancel(Text("Cancel")))
    }
    
    var resetAllAlert: Alert {
        let resetAction = {
//            SecurityService.shared.resetAll()
            devMenu = nil
        }
        
        return Alert(title: Text("Factory Reset"),
                     message: Text("Are you sure you want to do factory reset?"),
                     primaryButton: .default(Text("YES!"),
                                             action: resetAction),
                     secondaryButton: .cancel(Text("Cancel")))
    }
    
    var actionSheet: ActionSheet {
        ActionSheet(title: Text("Admin Panel"),
                    message: Text("In Dev"),
                    buttons: [.default(Text("OK"))])
    }
    
    var navBarBtn: some View {
        Button(action: {
            devMenu = nil
        }, label: {
            Image(systemName: "xmark.square.fill")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.aqua)
                .frame(width: 44, height: 44)
        })
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(
                    destination: DashboardView()
                        .environmentObject(DeviceRegistrationLandingDriver()),
                    isActive: $showDashboard,
                    label: { EmptyView() })
                
                Form {
                    Button(action: {
                        isLoading = true
                        showDashboard.toggle()
                    }, label: {
                        Text("Dashboard")
                    })
                    .menuCellStyle()
                    
                    Button(action: {
                        showResetAlert.toggle()
                    }, label: {
                        Text("Reset Registration")
                            .frame(maxWidth: .infinity)
                    })
                    .flatBtnStyle()

                    Button(action: {
                        fatalError("Crash was triggered")
                    }, label: {
                        Text("Force Crash")
                            .frame(maxWidth: .infinity)
                    })
                    .flatBtnStyle()

                    Button {
                        UserDefaults.standard.useFrontCamera.toggle()
                        cameraUsed = cameraUsed == .back ? .front : .back
                    } label: {
                        Text(cameraUsed.otherCameraText)
                            .frame(maxWidth: .infinity)
                    }
                    .flatBtnStyle()

                    HStack {
                        Button(action: {
                            jwtAlert.toggle()
                        }, label: {
                            Text("Input Registration JWT")
                                .frame(maxWidth: .infinity)
                        })
                        .flatBtnStyle()

                        Image(systemName: "circle.fill")
                            .foregroundStyle(registrationSuccess == nil ? .gray.opacity(0.6) : registrationSuccess == true ? .green : .red)
                    }

//                    Button(action: {
//                        showResetDatabaseAlert.toggle()
//                    }, label: {
//                        Text("Truncate Local Database")
//                            .frame(maxWidth: .infinity)
//                    })
//                    .flatBtnStyle(.primary(subtype: .destructive))
//                    .alert(isPresented: $showResetDatabaseAlert, content: { resetDatabaseAlert })
//                    
//                    Button(action: {
//                        showResetAll.toggle()
//                    }, label: {
//                        Text("Factory Reset")
//                            .frame(maxWidth: .infinity)
//                    })
//                    .flatBtnStyle(.primary(subtype: .destructive))
//                    .alert(isPresented: $showResetAll, content: { resetAllAlert })
                }
                
                if isLoading {
                    ProgressView()
                }
            }
            .navigationBarTitle("Dev Menu")
            .navigationBarItems(trailing: navBarBtn)
            .alert(isPresented: $showResetAlert, content: { resetAlert })
            .alert("Enter JWT token", isPresented: $jwtAlert) {
                TextField("JWT", text: $jwtToken)
                    .textInputAutocapitalization(.never)
                Button("OK", action: registerJWT)
                Button("Cancel", role: .cancel) { }
            }
        }
        .accentColor(.aqua)
    }

    private func registerJWT() {
        guard !jwtToken.isEmpty else { return }

        enrollmentDriver.$deviceValidatedAndRegistered
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { validatedAndRegistered in
                self.registrationSuccess = validatedAndRegistered
                if validatedAndRegistered == true {
                    self.cancellables.forEach { $0.cancel() }
                    self.cancellables.removeAll()
                }
            }
            .store(in: &cancellables)

        enrollmentDriver.enroll(using: jwtToken)
    }

    // MARK: - Init
    init(_ flow: Binding<DeviceRegistrationLandingDriver.ActiveModal?>) {
        self._devMenu = flow
    }
    
    fileprivate init() {
        self._devMenu = .constant(nil)
    }
}

// MARK: - Preview
struct DevMenuView_Previews: PreviewProvider {
    static var previews: some View {
        DevMenuView()
    }
}
