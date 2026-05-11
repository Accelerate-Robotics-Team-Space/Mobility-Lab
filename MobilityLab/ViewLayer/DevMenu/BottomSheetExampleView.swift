//
//  BottomSheetExampleView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/18/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BottomSheetExampleView: View {
    @State private var bottomSheetShown = false
    @State private var selectedText: String?
    let settings = [
        "Map", "Transit", "Satellite",
        "Resource", "Paralyzed", "Deficit",
        "Disorder", "Heel", "Policeman",
        "Nervous", "Bronze", "Acquit",
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TriggerField("Trigger Field", placeholder: "Some Placeholder", selectedText: $selectedText) {
                    withAnimation {
                        bottomSheetShown.toggle()
                    }
                }
                .padding()
                
                BottomSheetView(isOpen: $bottomSheetShown,
                                maxHeight: geometry.size.height * 0.7) {
                    Form {
                        ForEach(0 ..< settings.count, id: \.self) { index in
                            Button(action: {
                                self.selectedText = self.settings[index]
                                
                                withAnimation {
                                    bottomSheetShown.toggle()
                                }
                            }, label: {
                                Text(self.settings[index])
                            })
                            .menuCellStyle()
                        }
                    }
                }
            }
        }.edgesIgnoringSafeArea(.all)
    }
}

struct BottomSheetExampleView_Previews: PreviewProvider {
    static var previews: some View {
        BottomSheetExampleView()
    }
}
