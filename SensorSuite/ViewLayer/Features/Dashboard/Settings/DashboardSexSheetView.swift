//
//  DashboardSexSheetView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 3/14/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DashboardSexSheetView: View {
    @Binding var selectedSex: String
    @Binding var showBotSheet: Bool
    
    var altSexArray: [String] = [
        ALTSex.male.description,
        ALTSex.female.description,
        ALTSex.other.description,
        ALTSex.noAnswer.description,
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
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
            
            CustomPicker(dataArray: altSexArray,
                         selected: $selectedSex)
        }
    }
}

struct DashboardSexSheetView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardSexSheetView(selectedSex: .constant(ALTSex.female.description),
                              showBotSheet: .constant(true))
    }
}
