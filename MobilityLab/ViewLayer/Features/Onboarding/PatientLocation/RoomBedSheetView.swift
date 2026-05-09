//
//  RoomBedSheetView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/19/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct RoomBedSheetView: View {
    @ObservedObject var driver: PatientLocationDriver
    @Binding var showBotSheet: Bool
    @State var selectedRoom: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    guard let selectedRoom = selectedRoom,
                          let bedItem = driver.getRoomBedItemFromNumber(selectedRoom) else { return }
                    driver.selectRoomBed(bedItem)
                    withAnimation {
                        showBotSheet = false
                    }
                } label: {
                    Text("Done")
                        .bold()
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(Color.charcoal)
                }
            }
            .padding()

            CustomPicker(dataArray: driver.roomBedItems.map({ $0.roomBedNumber ?? "" }),
                         selected: $selectedRoom.toUnwrapped(defaultValue: ""))
        }
    }
    
    // MARK: - Init
    init(driver: PatientLocationDriver, showBotSheet: Binding<Bool>) {
        self.driver = driver
        self._showBotSheet = showBotSheet
        /*
         WARNING: Need to test if unitInfo actually has value. Meaning, there might be a case
         where there is no room/bed.
         */
        if !driver.roomBedItems.isEmpty {
            let count = driver.roomBedItems.count
            if driver.selectedRoomBed != nil, driver.roomBedItems.contains(where: { $0.roomBedNumber == driver.selectedRoomBedStr }) {
                self._selectedRoom = State(initialValue: driver.selectedRoomBed?.roomBedNumber)
            } else {
                self._selectedRoom = State(initialValue: driver.roomBedItems[count / 2].roomBedNumber)
            }
        }
    }
}

struct RoomBedSheetView_Previews: PreviewProvider {
    static var previews: some View {
        RoomBedSheetView(driver: PatientLocationDriver(),
                         showBotSheet: .constant(true))
    }
}
