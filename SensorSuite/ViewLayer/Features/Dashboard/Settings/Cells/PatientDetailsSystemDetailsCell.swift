//
//  PatientDetailsSystemDetailsCell.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 2/7/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientDetailsSystemDetailsCell: View {
    @StateObject private var viewModel = PatientDetailsSystemDetailsCellViewModel()

    var body: some View {
        VStack {
            HStack {
                Text(R.string.localizable.system())
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(.charcoal1)
                Spacer()
            }
            Spacer()
                .frame(height: 16)
            HStack {
                Text("Turn Protocol")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.charcoal1)
                Spacer()
                Text(viewModel.turnProtocol)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal3)
                    .lineLimit(2)
            }
            Divider()
            HStack {
                Text("Effective Turn Angle")
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.charcoal1)
                Spacer()
                Text(viewModel.complianceAngle)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal3)
                    .lineLimit(2)
            }
            Divider()
            HStack {
                Text(R.string.localizable.patientId())
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.charcoal1)
                Spacer()
                Text(viewModel.patient)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Divider()
            HStack {
                Text(R.string.localizable.deviceId())
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.charcoal1)
                Spacer()
                Text(viewModel.deviceID)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding()
        .background(Color.charcoal5)
        .cornerRadius(16)
    }
}

#Preview {
    PatientDetailsSystemDetailsCell()
}
