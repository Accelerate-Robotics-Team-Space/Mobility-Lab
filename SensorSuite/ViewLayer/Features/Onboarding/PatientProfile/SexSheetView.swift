//
//  sexSheetView.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/19/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SexSheetView: View {
    @ObservedObject var driver: PatientProfileDriver
    @Binding var showBotSheet: Bool
    @State var selectedSex: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    switch selectedSex {
                    case ALTSex.female.description:
                        driver.patientManager.cachePatient.sex = .female
                    case ALTSex.male.description:
                        driver.patientManager.cachePatient.sex = .male
                    case ALTSex.noAnswer.description:
                        driver.patientManager.cachePatient.sex = .noAnswer
                    case ALTSex.other.description:
                        driver.patientManager.cachePatient.sex = .other
                    default:
                        driver.patientManager.cachePatient.sex = .noAnswer
                    }
                    
                    driver.selectIndex(for: .sex(index: driver.getSexIndexFromDescription(description: selectedSex)))
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

            CustomPicker(dataArray: driver.sexRange.map({ $0.description }), selected: $selectedSex)
        }
    }
    
    // MARK: - Init
    init(driver: PatientProfileDriver, showBotSheet: Binding<Bool>) {
        self.driver = driver
        self._showBotSheet = showBotSheet
        let initialValue = driver.selectedSex == nil ? "Female" : driver.selectedSex
        self._selectedSex = State(initialValue: initialValue!)
    }
}

struct SexSheetView_Previews: PreviewProvider {
    static var previews: some View {
        SexSheetView(driver: PatientProfileDriver(),
                     showBotSheet: .constant(true))
    }
}
