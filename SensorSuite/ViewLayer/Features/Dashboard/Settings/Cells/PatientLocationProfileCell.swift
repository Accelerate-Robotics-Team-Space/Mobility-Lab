//
//  PatientLocationProfileCell.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 11/16/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct PatientLocationProfileCell: View {
    @Binding var modal: ProfileDriver.ProfileActiveModal?
	@EnvironmentObject var patientLocationDriver: PatientLocationDriver
	
    private var location: PatientLocation?
    private let unknownStr = R.string.localizable.unknown()
    @Injected(\.userDefaults) private var userDefaults

    var body: some View {
        VStack {
            HStack {
                Image(R.image.patientLocationIcon.name)
                Text(R.string.localizable.location())
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(.charcoal1)
                Spacer()
                Button {
                    displayLocationEditModal()
                } label: {
                    Text(R.string.localizable.edit().uppercased())
                        .foregroundColor(.white)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.black.opacity(0.4))
                )
            }
            HStack {
                Button {
					displayLocationEditModal()
                } label: {
                    Text(R.string.localizable.facility())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(userDefaults.facilityName ?? "Unknown")
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
            }
            Divider()
            HStack {
                Button {
                    displayLocationEditModal()
                } label: {
                    Text(R.string.localizable.unit())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(location?.unit.name ?? unknownStr)
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
            }
            Divider()
            HStack {
                Button {
                    displayLocationEditModal()
                } label: {
                    Text(R.string.localizable.room())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(location?.roomBed.roomBedNumber ?? unknownStr)
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
            }
        }
        .padding()
        .background(Color.charcoal5)
        .cornerRadius(16)
    }
    
    // MARK: - Init
    init(for location: PatientLocation?, modal: Binding<ProfileDriver.ProfileActiveModal?>) {
        self.location = location
        self._modal = modal
    }
	
	func displayLocationEditModal() {
		if let unit = patientLocationDriver.selectedUnit {
			patientLocationDriver.selectUnit(unit)
		}
		withAnimation(.spring().speed(0.9)) {
			modal = .location
		}
	}
}

struct PatientLocationProfileCell_Previews: PreviewProvider {
    static var previews: some View {
        PatientLocationProfileCell(for: nil, modal: .constant(nil))
    }
}
