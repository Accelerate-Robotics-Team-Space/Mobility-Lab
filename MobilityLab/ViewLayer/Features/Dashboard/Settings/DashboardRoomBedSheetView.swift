//
//  DashboardRoomBedSheetView.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 3/9/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DashboardRoomBedSheetView: View {
	@ObservedObject var driver: PatientLocationDriver
	@State var selectedRoom: String?
    @Binding var showBotSheet: Bool
   
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
					if let selectedRoom = selectedRoom,
					   let bedItem = driver.getRoomBedItemFromNumber(selectedRoom) {
						driver.selectRoomBed(bedItem)
					} else {
						driver.selectFirstRoomBedItem()
					}
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
}

struct DashboardRoomBedSheetView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardRoomBedSheetView(driver: PatientLocationDriver(),
                                  showBotSheet: .constant(true))
    }
}
