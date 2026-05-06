//
//  PatientLocationProfileCell.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 11/1/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientLocationProfileCell: View {
    @ObservedObject var bmmViewModel: BMMViewModel
    
    private(set) var unit: String?
    private(set) var roomBed: String?
    
    var body: some View {
        VStack {
            Button {
                if bmmViewModel.currentOpening != .patientLocation {
                    bmmViewModel.currentOpening = .patientLocation
                } else {
                    bmmViewModel.currentOpening = .none
                }
            } label: {
                HStack {
                    Image(R.image.patientLocationIcon.name)
                        .resizable()
                        .frame(width: 26, height: 26)
                    HStack { }
                        .frame(width: 12)
                    Text(R.string.localizable.location())
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Image(R.image.arrowDown.name)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(bmmViewModel.currentOpening == .patientLocation ? -180 : 0))
                        .animation(.spring(), value: bmmViewModel.currentOpening)
                }
            }
            if bmmViewModel.currentOpening == .patientLocation {
                VStack { }
                    .frame(height: 4)
                HStack {
                    Text(R.string.localizable.unit())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(bmmViewModel.cardData.canShowPatientDetails ? unit ?? R.string.localizable.unknown() : "-")
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
                Divider()
                HStack {
                    Text(R.string.localizable.room())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(bmmViewModel.cardData.canShowPatientDetails ? roomBed ?? R.string.localizable.unknown() : "-")
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Init
    init(bmmViewModel: BMMViewModel, unit: String? = nil, roomBed: String? = nil) {
        self.bmmViewModel = bmmViewModel
        self.unit = unit
        self.roomBed = roomBed
    }
}

struct PatientLocationProfileCell_Previews: PreviewProvider {
    static var previews: some View {
        PatientLocationProfileCell(bmmViewModel: BMMViewModel(),
                                   unit: "ICU",
                                   roomBed: "B123-A")
    }
}
