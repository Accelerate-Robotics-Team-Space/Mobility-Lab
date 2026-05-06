//
//  UnitSheetView.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/19/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct UnitSheetView: View {
    @ObservedObject var driver: PatientLocationDriver
    @Binding var showBotSheet: Bool
    @Binding var showAlert: Bool
    
    @State var selectedUnit: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    guard let unitName = selectedUnit else { return }
                    if unitName != driver.selectedUnit?.name,
                       let unit = driver.getUnitFromName(unitName) {
                        driver.selectUnit(unit)
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

            CustomPicker(dataArray: driver.unitInfo.map({ $0.name ?? "" }),
                         selected: $selectedUnit.toUnwrapped(defaultValue: ""))
        }
    }
    
    // MARK: - Init
    init(driver: PatientLocationDriver, showBotSheet: Binding<Bool>, showAlert: Binding<Bool>) {
        self.driver = driver
        self._showBotSheet = showBotSheet
        self._showAlert = showAlert
        /*
         WARNING: Need to test if unitInfo actually has value. Meaning, there might be a case
         where there is no unit.
         */
		
		if !driver.unitInfo.isEmpty {
			let count = driver.unitInfo.count
			let initialValue = driver.selectedUnit == nil ? driver.unitInfo[count / 2].name : driver.selectedUnit?.name
			self._selectedUnit = State(initialValue: initialValue)
		}
    }

    init(showBotSheet: Binding<Bool>, showAlert: Binding<Bool>, defaultUnitValue: String) {
        self.driver = PatientLocationDriver()
        self._showBotSheet = showBotSheet
        self._showAlert = showAlert
        self._selectedUnit = State(initialValue: defaultUnitValue)
    }
}

struct UnitSheetView_Previews: PreviewProvider {
    static var previews: some View {
        UnitSheetView(driver: PatientLocationDriver(),
                      showBotSheet: .constant(true),
                      showAlert: .constant(false))
            .previewDevice((PreviewDevice(rawValue: "iPhone 8 Plus")))
    }
}
