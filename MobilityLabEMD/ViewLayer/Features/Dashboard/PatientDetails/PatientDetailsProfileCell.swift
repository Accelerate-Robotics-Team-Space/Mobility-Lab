//
//  PatientDetailsProfileCell.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 11/1/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientDetailsProfileCell: View {
    @ObservedObject var bmmViewModel: BMMViewModel
    
    @State var bmiValue = 0.0
    private(set) var patientDetailsViewModel: PatientDetailsViewModel
    
    private enum Constants {
        static let bmiCoefficient = 70300
    }
    
    var body: some View {
        VStack {
            Button {
                if bmmViewModel.currentOpening != .patientDetails {
                    bmmViewModel.currentOpening = .patientDetails
                } else {
                    bmmViewModel.currentOpening = .none
                }
            } label: {
                HStack {
                    Image(R.image.patientDetailsIcon.name)
                        .resizable()
                        .frame(width: 26, height: 26)
                    HStack { }
                        .frame(width: 12)
                    Text(R.string.localizable.details())
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Image(R.image.arrowDown.name)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(bmmViewModel.currentOpening == .patientDetails ? -180 : 0))
                        .animation(.spring(), value: bmmViewModel.currentOpening)
                }
            }
            if bmmViewModel.currentOpening == .patientDetails {
                VStack { }
                    .frame(height: 4)
                HStack {
                    Text(R.string.localizable.height())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(self.bmmViewModel.cardData.canShowPatientDetails ? "\(patientDetailsViewModel.heightInInches!)" : "-")
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
                Divider()
                HStack {
                    Text(R.string.localizable.weight())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(self.bmmViewModel.cardData.canShowPatientDetails ? "\(patientDetailsViewModel.weightInPounds!)" : "-")
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
                Divider()
                HStack {
                    Text("BMI Value")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(self.bmmViewModel.cardData.canShowPatientDetails ? "\(String(format: "%.2f", bmiValue))" : "-")
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
                Divider()
                HStack {
                    Text(R.string.localizable.sex())
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Text(self.bmmViewModel.cardData.canShowPatientDetails 
                         ? (patientDetailsViewModel.sex?.description ?? R.string.localizable.unknown())
                         : "-")
                        .font(.custom("Avenir-Roman", size: 16))
                        .foregroundColor(.charcoal3)
                }
            }
        }
        .padding()
        .onReceive(patientDetailsViewModel.$heightInInches) { _ in
            updateBMI()
        }
        .onReceive(patientDetailsViewModel.$weightInPounds) { _ in
            updateBMI()
        }
    }
    
    private func updateBMI() {
        guard let height = patientDetailsViewModel.heightInInches, height != 0 else {
            logger.info("check Value: nil, missing height")
            return
        }
        guard let weight = patientDetailsViewModel.weightInPounds, weight != 0 else {
            logger.info("check Value: nil, missing weight")
            return
        }
        
        let heightSquared = Double(height * height)
        let weightDividedByHeightSquared = Double(weight) / heightSquared
        
        let rawBmi = weightDividedByHeightSquared * Double(Constants.bmiCoefficient)

        bmiValue = round(rawBmi) / 100.0
        
        logger.info("check Value: \(bmiValue)")
    }
}

struct PatientDetailsProfileCell_Previews: PreviewProvider {
    static var previews: some View {
        PatientDetailsProfileCell(
            bmmViewModel: BMMViewModel(),
            patientDetailsViewModel: PatientDetailsViewModel(
                id: "an id",
                weightInPounds: 166,
                heightInInches: 64,
                sex: ALTSex.female
            )
        )
    }
}
