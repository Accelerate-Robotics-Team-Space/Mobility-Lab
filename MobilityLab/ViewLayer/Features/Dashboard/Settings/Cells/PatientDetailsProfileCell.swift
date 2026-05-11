//
//  PatientDetailsProfileCell.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/16/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientDetailsProfileCell: View {
    @Binding var modal: ProfileDriver.ProfileActiveModal?
    
    private var somePatient: ALTPatient?
    private let unknownStr = R.string.localizable.unknown()
    
    var body: some View {
        VStack {
            HStack {
                Image(R.image.patientDetailsIcon.name)
                Text(R.string.localizable.details())
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(.charcoal1)
                Spacer()
                Button {
                    withAnimation(.spring().speed(0.9)) {
                        modal = .details
                    }
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
                    withAnimation(.spring().speed(0.9)) {
                        modal = .details
                    }
                } label: {
                    Text(R.string.localizable.height())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(somePatient?.formattedHeight ?? unknownStr)
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
            }
            Divider()
            HStack {
                Button {
                    withAnimation(.spring().speed(0.9)) {
                        modal = .details
                    }
                } label: {
                    Text(R.string.localizable.weight())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(somePatient?.formattedWeight ?? unknownStr)
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
            }
            Divider()
            HStack {
                Button {
                    withAnimation(.spring().speed(0.9)) {
                        modal = .details
                    }
                } label: {
                    Text("BMI Value")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text("\(String(format: "%.2f", somePatient?.bmi ?? 999.99))")
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
            }
            Divider()
            HStack {
                Button {
                    withAnimation(.spring().speed(0.9)) {
                        modal = .details
                    }
                } label: {
                    Text(R.string.localizable.sex())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(somePatient?.sex.description ?? unknownStr)
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
    init(for patient: ALTPatient?, modal: Binding<ProfileDriver.ProfileActiveModal?>) {
        self.somePatient = patient
        self._modal = modal
    }
}

struct PatientDetailsProfileCell_Previews: PreviewProvider {
    static var previews: some View {
        PatientDetailsProfileCell(for: nil, modal: .constant(nil))
    }
}
