//
//  PatientProfileSettingsCell.swift
//  SensorSuite
//
//  Created by Josh Franco on 2/10/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientProfileSettingsCell: View {
    private let cornerRad: CGFloat = 5
    private let outlineWidth: CGFloat = 1
    private let unknownStr = R.string.localizable.unknown()
    private var somePatient: ALTPatient?
    private var action: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            R.string.localizable.patientProfile.text
                .textStyle(.header6)
                .foregroundColor(.charcoal)
            
            HStack {
                VStack {
                    R.string.localizable.height.text
                        .textStyle(.body1)
                        .foregroundColor(.charcoal)
                    
                    Text(somePatient?.formattedHeight ?? unknownStr)
                        .textStyle(.body2)
                        .foregroundColor(.charcoal)
                }
                
                Spacer()
                
                VStack {
                    R.string.localizable.weight.text
                        .textStyle(.body1)
                        .foregroundColor(.charcoal)
                    
                    Text(somePatient?.formattedWeight ?? unknownStr)
                        .textStyle(.body2)
                        .foregroundColor(.charcoal)
                }
            }
            
            HStack {
                R.string.localizable.sex.text
                    .textStyle(.body1)
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                Text(somePatient?.sex.description ?? unknownStr)
                    .textStyle(.body2)
                    .foregroundColor(.charcoal)
            }
            
//            HStack {
//                R.string.localizable.bodyType.text
//                    .textStyle(.body1)
//                    .foregroundColor(.charcoal)
//                
//                Spacer()
//                
//                Text(somePatient?.bmi.description ?? unknownStr)
//                    .textStyle(.body2)
//                    .foregroundColor(.charcoal)
//            }
            
            Button(action: {
                action()
            }, label: {
                R.string.localizable.editPatientProfile.text
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
    init(for patient: ALTPatient?, action: @escaping () -> Void) {
        self.somePatient = patient
        self.action = action
    }
}

// MARK: - Preview
struct PatientProfileSettingsCell_Previews: PreviewProvider {
    static var previews: some View {
        PatientProfileSettingsCell(for: nil) {
            // Do stuff in this block
        }
    }
}
