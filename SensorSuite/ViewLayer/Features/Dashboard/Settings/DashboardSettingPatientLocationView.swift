//
//  DashboardSettingPatientLocationView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 3/8/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DashboardSettingPatientLocationView: View {
    @Binding var patientProfileFlow: ProfileDriver.ProfileActiveModal?

    @State var roomBedItems: [HospitalRoomBed]?
    @State var selectedRoomBedOG: String?
    @State var currentSelection = PatientLocationSelection.unit
    @State var showBotSheet: Bool = false
    @State var showAlert: Bool = false

    @ObservedObject var patientLocationDriver: PatientLocationDriver

    private var locationAlert: Alert {
        Alert(title: R.string.localizable.unitHasNoRooms.text)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                VStack {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            editPatientLocationButton

                            whereIsPatientText
                        }
                    }

                    Spacer()

                    VStack {
                        unitField
                        roomBedField
                    }

                    VStack { }
                        .frame(height: 16)

                    saveButton
                    .padding(.bottom, geo.safeAreaInsets.bottom)
                }
                .padding(.all, 16)
                .background(mainVStackBackground)
                .alert(isPresented: $showAlert, content: { locationAlert })
                .onTapGesture(count: 1) {
                    guard showBotSheet == true else { return }
                    toggleBotSheet()
                }

                if showBotSheet {
                    gradientView
                }

                bottomSheetView(geo)
            }
            .padding(.bottom, -geo.safeAreaInsets.bottom)
            .background(Color.white.opacity(0.1))
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    var editPatientLocationButton: some View {
        HStack {
            Text(R.string.localizable.editPatientLocation())
                .font(.custom("Avenir-Heavy", size: 24))
                .foregroundColor(.charcoal3)

            Spacer()

            Button(action: {
                resetAndDismiss()
            }) {
                Image(R.image.cross.name)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.charcoal3)
            }
        }
    }

    @ViewBuilder
    var whereIsPatientText: some View {
        VStack(alignment: .leading) {
            Text("Where is your")
                .font(.custom("Avenir-Heavy", size: 24))
                .multilineTextAlignment(.leading)
                .foregroundColor(.charcoal)
            Text("patient located?")
                .font(.custom("Avenir-Heavy", size: 24))
                .multilineTextAlignment(.leading)
                .foregroundColor(.charcoal)
        }
    }

    @ViewBuilder
    var roomBedField: some View {
        TriggerField(
            R.string.localizable.roomBed(),
            placeholder: R.string.localizable.selectPatientRoom(),
            selectedText: $patientLocationDriver.selectedRoomBedStr
        ) {
            currentSelection = .room
            toggleBotSheet()
        }
        .disabled(patientLocationDriver.isRoomBedFieldDisabled)
    }

    @ViewBuilder
    var unitField: some View {
        TriggerField(
            R.string.localizable.unit(),
            placeholder: R.string.localizable.selectPatientUnit(),
            selectedText: $patientLocationDriver.selectedUnitStr
        ) {
            currentSelection = .unit
            toggleBotSheet()
        }
    }

    @ViewBuilder
    var saveButton: some View {
        VStack(spacing: 16) {
            Button(action: {
                patientLocationDriver.goNextBtnPress {
                    dismiss()
                }
            }, label: {
                Text(R.string.localizable.save())
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(patientLocationDriver.canGoNext ? ALTButtonStyle() : ALTButtonStyle.altBtnIndigoDisabled())
            .contentShape(Rectangle())
            .disabled(!patientLocationDriver.canGoNext)
            Button(action: {
                resetAndDismiss()
            }, label: {
                Text(R.string.localizable.cancel())
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(FlatButtonStyle(.clear()))
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    var mainVStackBackground: some View {
        Rectangle()
            .fill(Color.white)
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 2,
                x: 0,
                y: 0
            )
    }

    @ViewBuilder
    var gradientView: some View {
        VStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        .faintingLight.opacity(0),
                        .faintingLight.opacity(0.2),
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .padding(.top, 0)
    }

    @ViewBuilder
    func bottomSheetView(_ geo: GeometryProxy) -> some View {
        BottomSheetView(isOpen: $showBotSheet, maxHeight: 320) {
            switch currentSelection {
            case .unit:
                DashboardUnitSheetView(
                    driver: patientLocationDriver,
                    selectedUnit: patientLocationDriver.selectedUnitStr,
                    showBotSheet: $showBotSheet,
                    showAlert: $showAlert
                )
                .padding(.bottom, geo.safeAreaInsets.bottom)
            case .room:
                DashboardRoomBedSheetView(
                    driver: patientLocationDriver,
                    selectedRoom: patientLocationDriver.selectedRoomBedStr,
                    showBotSheet: $showBotSheet
                )
                .padding(.bottom, geo.safeAreaInsets.bottom)
            }
        }
    }

    // MARK: - Init
    init(
		flow: Binding<ProfileDriver.ProfileActiveModal?>,
		patientLocationDriver: PatientLocationDriver
	) {
        _patientProfileFlow = flow
		self.patientLocationDriver = patientLocationDriver
    }
}

extension DashboardSettingPatientLocationView {
    private func toggleBotSheet() {
        withAnimation {
            showBotSheet.toggle()
        }
    }

    private func resetAndDismiss() {
        patientLocationDriver.resetFromPatient()
        dismiss()
    }

    private func dismiss() {
        withAnimation(.spring().speed(1.3)) {
            patientProfileFlow = nil
        }
    }
}

struct DashboardSettingPatientLocationView_Previews: PreviewProvider {
    static var previews: some View {
		DashboardSettingPatientLocationView(flow: .constant(nil), patientLocationDriver: PatientLocationDriver())
    }
}
