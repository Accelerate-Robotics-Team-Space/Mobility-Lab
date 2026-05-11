//
//  BodyTypeSheetView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/19/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BodyTypeSheetView: View {
    @ObservedObject var driver: PatientProfileDriver
    @Binding var showBotSheet: Bool
    @State var selectedBodyTypeIndex: Int
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    driver.selectIndex(for: .bodyType(index: selectedBodyTypeIndex))
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
                
                Picker("Units", selection: $selectedBodyTypeIndex) {
                    ForEach(0..<driver.bodyTypeRange.count, id: \.self) { index in
                        Text(driver.bodyTypeRange[index].description)
                            .tag(index)
                            .modifier(ColorAnimation(index == selectedBodyTypeIndex, from: .white, to: .black))
                    }
                }
                .padding()
                .pickerStyle(.wheel)
            }
        }
    }
    
    // MARK: - Init
    init(driver: PatientProfileDriver, showBotSheet: Binding<Bool>) {
        self.driver = driver
        self._showBotSheet = showBotSheet
        let initialValue = driver.bodyTypeIndex == nil ? 1 : driver.bodyTypeIndex
        self._selectedBodyTypeIndex = State(initialValue: initialValue!)
    }
}

struct BodyTypeSheetView_Previews: PreviewProvider {
    static var previews: some View {
        BodyTypeSheetView(driver: PatientProfileDriver(),
                          showBotSheet: .constant(true))
    }
}
