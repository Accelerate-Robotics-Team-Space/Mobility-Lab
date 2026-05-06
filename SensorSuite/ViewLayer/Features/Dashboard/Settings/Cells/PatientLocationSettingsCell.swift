//
//  PatientLocationSettingsCell.swift
//  SensorSuite
//
//  Created by Josh Franco on 2/10/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientLocationSettingsCell: View {
    private let cornerRad: CGFloat = 5
    private let outlineWidth: CGFloat = 1
    private let unknownStr = R.string.localizable.unknown()
    private var location: PatientLocation?
    private var action: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            R.string.localizable.patientLocation.text
                .textStyle(.header6)
                .foregroundColor(.charcoal)
            
            HStack {
                R.string.localizable.unit.text
                    .textStyle(.body1)
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                Text("\(location?.unit.name ?? unknownStr)")
                    .textStyle(.body2)
                    .foregroundColor(.charcoal)
            }
            
            HStack {
                R.string.localizable.roomBed.text
                    .textStyle(.body1)
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                Text("\(location?.roomBed.roomBedNumber ?? unknownStr)")
                    .textStyle(.body2)
                    .foregroundColor(.charcoal)
            }
            
            Button(action: {
                action()
            }, label: {
                R.string.localizable.editPatientLocation.text
                    .frame(maxWidth: .infinity)
            })
            .flatBtnStyle()
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: cornerRad)
                .stroke(Color.charcoal, lineWidth: outlineWidth)
        )
    }
    
    // MARK: - Init
    init(for location: PatientLocation?, action: @escaping () -> Void) {
        self.location = location
        self.action = action
    }
}

// MARK: - Preview
struct PatientLocationSettingsCell_Previews: PreviewProvider {
    static var previews: some View {
        PatientLocationSettingsCell(for: nil) {
            // Do stuff in this block
        }
    }
}
