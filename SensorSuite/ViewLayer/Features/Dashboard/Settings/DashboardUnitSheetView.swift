//
//  DashboardUnitSheetView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 3/9/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DashboardUnitSheetView: View {
	@ObservedObject var driver: PatientLocationDriver
    @State var selectedUnit: String?
    @Binding var showBotSheet: Bool
    @Binding var showAlert: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
					guard let selectedUnit = selectedUnit else { return }
					if selectedUnit != driver.selectedUnit?.name {
						driver.selectUnit(driver.getUnitFromName(selectedUnit)!)
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
            
            CustomPicker(dataArray: driver.unitInfo.map { $0.name ?? "" },
                         selected: $selectedUnit.toUnwrapped(defaultValue: ""))
        }
    }
}

struct DashboardUnitSheetView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardUnitSheetView(
			driver: PatientLocationDriver(),
			showBotSheet: .constant(true),
			showAlert: .constant(false)
		)
    }
}
