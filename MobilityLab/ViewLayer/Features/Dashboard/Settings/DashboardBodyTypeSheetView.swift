//
//  DashboardBodyTypeSheetView.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 3/14/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DashboardBodyTypeSheetView: View {
    @Binding var selectedBodyType: String?
    @Binding var showBotSheet: Bool
    
    var altBodyTypeArray: [String?] = [
        ALTBodyType.round.description,
        ALTBodyType.muscular.description,
        ALTBodyType.slim.description,
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
            
            /*
             Work around to change picker's highlight color
             Ref: https://stackoverflow.com/questions/64523972/swiftui-picker-change-selected-row-color
             */
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 365, height: 32)
                    .foregroundColor(.green1)
                
                Picker("Units", selection: $selectedBodyType) {
                    ForEach(altBodyTypeArray, id: \.self) { bodyType in
                        Text(bodyType ?? "?")
                            .tag(bodyType)
                            .modifier(ColorAnimation(bodyType == selectedBodyType,
                                                     from: .white,
                                                     to: .black))
                    }
                }
                .padding()
                .pickerStyle(.wheel)
            }
        }
    }
}

struct DashboardBodyTypeSheetView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardBodyTypeSheetView(selectedBodyType: .constant(ALTBodyType.muscular.description),
                                   showBotSheet: .constant(true))
    }
}
