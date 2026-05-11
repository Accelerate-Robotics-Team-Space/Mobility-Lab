//
//  EditPatientLocationView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 11/17/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct EditPatientLocationView: View {
    @ObservedObject var bmmViewModel: BMMViewModel
    @Binding var profileModal: DashboardDriver.ProfileActiveModal
    
    @State var selectedUnitOG: String?
    @State var selectedUnit: String?
    @State var roomBedItemsOG: [HospitalRoomBed]?
    @State var roomBedItems: [HospitalRoomBed]?
    @State var selectedRoomBedOG: String?
    @State var selectedRoomBed: String?
    @State var showBotSheet = false
    @State var showAlert = false
    @State var picker = LocationPicker.none
    
    enum LocationPicker {
        case unit
        case roomBed
        case none
    }

    var body: some View {
        ZStack {
            VStack {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
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
                        VStack {
                            Text(R.string.localizable.wherePatientLocated())
                                .font(.custom("Avenir-Heavy", size: 24))
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.charcoal)
                        }
                        .padding(.trailing, 37)
                    }
                }
                VStack {
                    VStack(alignment: .leading) {
                        Text("Unit")
                            .textStyle(.btn)
                        Button(action: {
                            picker = .unit
                        }, label: {
                            HStack {
                                Text(selectedUnit ?? "Unknown")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .bold()
                                    .foregroundColor(selectedUnit == nil ? .charcoal4 : .charcoal1)
                                Spacer()
                                Image(R.image.arrowDown.name)
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.charcoal)
                                    .frame(width: 12, height: 12)
                            }
                        })
                        .padding(.all, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .defaultShadows()
                        )
                    }
                    VStack(alignment: .leading) {
                        Text("Room/Bed")
                            .textStyle(.btn)
                        Button(action: {
                            picker = .roomBed
                        }, label: {
                            HStack {
                                Text(selectedRoomBed ?? "Unknown")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .bold()
                                    .foregroundColor(selectedRoomBed == nil ? .charcoal4 : .charcoal1)
                                Spacer()
                                Image(R.image.arrowDown.name)
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.charcoal)
                                    .frame(width: 12, height: 12)
                            }
                        })
                        .padding(.all, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .defaultShadows()
                        )
                    }
                }
                Spacer()
                VStack(spacing: 16) {
                    Button(action: {
                        guard let selectedUnit = selectedUnit else { return }
                        guard let selectedRoomBed = selectedRoomBed else { return }
                        bmmViewModel.unit = selectedUnit
                        bmmViewModel.roomBed = selectedRoomBed
                        saveAndDismiss()
                    }, label: {
                        Text(R.string.localizable.save())
                            .frame(maxWidth: .infinity)
                    })
                    .buttonStyle(FlatButtonStyle(.primary()))
                    Button(action: {
                        resetAndDismiss()
                    }, label: {
                        Text(R.string.localizable.cancel())
                            .frame(maxWidth: .infinity)
                    })
                    .buttonStyle(FlatButtonStyle(.clear()))
                }
            }
            .padding(.all, 16)
            .background(
                Rectangle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1),
                            radius: 2,
                            x: 0,
                            y: 0)
            )
            if picker == .unit {
                VStack {
                    HStack {
                        Text("Unit")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.charcoal)
                        Spacer()
                        Button {
                            for unit in HospitalUnitInfo.getAll() where unit.name == selectedUnit! {
                                roomBedItems = unit.roomBeds
                                if !roomBedItems!.isEmpty {
                                    selectedRoomBed = roomBedItems![roomBedItems!.count / 2].roomBedNumber
                                }
                            }
                            picker = .none
                        } label: {
                            Text("Done")
                        }
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(height: 32)
                            .foregroundColor(.green1)
                        Picker("Units", selection: $selectedUnit) {
                            ForEach(HospitalUnitInfo.getAll()) { unit in
                                Text(unit.name ?? "?")
                                    .tag(unit.name)
                                    .modifier(ColorAnimation(unit.name == selectedUnit, from: .white, to: .black))
                            }
                        }
                    }
                    .navigationBarHidden(true)
                    .pickerStyle(.wheel)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .frame(width: 300, height: 200)
            } else if picker == .roomBed {
                VStack {
                    HStack {
                        Text("Room/Bed")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.charcoal)
                        Spacer()
                        Button {
                            picker = .none
                        } label: {
                            Text("Done")
                        }
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(height: 32)
                            .foregroundColor(.green1)
                        Picker("Room/Bed", selection: $selectedRoomBed) {
                            ForEach(roomBedItems!) { item in
                                Text(item.roomBedNumber ?? "?")
                                    .tag(item.roomBedNumber)
                                    .modifier(ColorAnimation(item.roomBedNumber == selectedRoomBed!, from: .white, to: .black))
                            }
                        }
                    }
                    .navigationBarHidden(true)
                    .pickerStyle(.wheel)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .frame(width: 300, height: 200)
            }
        }
    }
    
    // MARK: - Init
    init(viewModel: BMMViewModel, flow: Binding<DashboardDriver.ProfileActiveModal>) {
        self.bmmViewModel = viewModel
        _selectedUnit = State(initialValue: viewModel.unit)
        _selectedUnitOG = _selectedUnit
        _selectedRoomBed = State(initialValue: viewModel.roomBed)
        _selectedRoomBedOG = _selectedRoomBed
        _profileModal = flow
        
        for unit in HospitalUnitInfo.getAll() where unit.name == selectedUnit {
            _roomBedItems = State(initialValue: unit.roomBeds)
            _roomBedItemsOG = _roomBedItems
        }
    }
}

private extension EditPatientLocationView {
    func resetAndDismiss() {
        selectedUnit = selectedUnitOG
        selectedRoomBed = selectedRoomBedOG
        withAnimation(.spring().speed(1.3)) {
            profileModal = .none
        }
    }
    func saveAndDismiss() {
        selectedUnitOG = selectedUnit
        selectedRoomBedOG = selectedRoomBed
        withAnimation(.spring().speed(1.3)) {
            profileModal = .none
        }
    }
}

struct EditPatientLocationView_Previews: PreviewProvider {
    static var previews: some View {
        EditPatientLocationView(viewModel: BMMViewModel(), flow: .constant(.location))
    }
}
