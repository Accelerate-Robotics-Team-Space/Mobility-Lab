//
//  ProfileComplianceAngleSelectionView.swift
//  MobilityLab BMM
//
//  Created by Vadym Riznychok on 4/1/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct ProfileComplianceAngleSelectionView: View {
    @Binding var showBotSheet: Bool
    @Binding var selectedString: String?
    @State var selectedCompliance: String

    @Injected(\.userDefaults) private var userDefaults

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    if let compliance = ComplianceAngle(fromReadable: selectedCompliance) {
                        userDefaults.complianceAngle = compliance
                        selectedString = selectedCompliance
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

            CustomPicker(dataArray: ComplianceAngle.allCases.map({ $0.readable }), selected: $selectedCompliance)
        }
    }

    // MARK: - Init
    init(showBotSheet: Binding<Bool>, selectedString: Binding<String?>) {
        self._showBotSheet = showBotSheet
        self._selectedString = selectedString
        self._selectedCompliance = State(initialValue: "")
        self._selectedCompliance = State(initialValue: userDefaults.complianceAngle!.readable)
    }
}

#Preview {
    ProfileComplianceAngleSelectionView(showBotSheet: .constant(false), selectedString: .constant(""))
}
