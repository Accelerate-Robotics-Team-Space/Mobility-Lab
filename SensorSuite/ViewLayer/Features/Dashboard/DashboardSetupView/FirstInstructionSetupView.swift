//
//  FirstInstructionSetupView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 12/7/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct FirstInstructionSetupView: View {
    @State private var offset = 190.0

    var body: some View {
        VStack {
            Text("Wake the sensor by clicking on the digital crown")
                .bold()
                .foregroundColor(.charcoal1)
            Text(R.string.localizable.pleasePairAWearable())
            Spacer()
                .frame(height: 30)
            ZStack {
                Image(R.image.wakeWearable.name)
                ZStack {
                    Image(systemName: "hand.point.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .offset(x: offset, y: -60)
                        .onAppear {
                            withAnimation(.spring().repeatForever()) {
                                offset = 185.0
                            }
                        }
                }
            }
        }
    }
}

struct FirstInstructionSetupView_Previews: PreviewProvider {
    static var previews: some View {
        FirstInstructionSetupView()
    }
}
