//
//  ProfileTurnProtocolSelectionView.swift
//  MobilityLab BMM
//
//  Created by Vadym Riznychok on 4/1/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct ProfileTurnProtocolSelectionView: View {
    @Binding var showBotSheet: Bool
    @Binding var selectedString: String?
    @State var selectedTurn: TurnProtocol

    @Injected(\.userDefaults) private var userDefaults

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    userDefaults.turnProtocol = selectedTurn
                    selectedString = selectedTurn.rawValue
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

            CustomPicker(dataArray: TurnProtocol.allCases, selected: $selectedTurn)
        }
    }

    // MARK: - Init
    init(showBotSheet: Binding<Bool>, selectedString: Binding<String?>) {
        self._showBotSheet = showBotSheet
        self._selectedString = selectedString
        self._selectedTurn = State(initialValue: .Q2)
        self._selectedTurn = State(initialValue: userDefaults.turnProtocol!)
    }
}

#Preview {
    ProfileTurnProtocolSelectionView(showBotSheet: .constant(false), selectedString: .constant(""))
}
