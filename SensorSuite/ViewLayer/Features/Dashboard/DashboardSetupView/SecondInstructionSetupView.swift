//
//  SecondInstructionSetupView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 12/7/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SecondInstructionSetupView: View {
    @State private var offset = -75.0

    var body: some View {
        VStack {
            Text("Click on the SensorSuite icon")
                .bold()
                .foregroundColor(.charcoal1)
            Text(R.string.localizable.pleasePairAWearable())
            Spacer()
                .frame(height: 30)
            ZStack {
                Image(R.image.selectApplication.name)
                Image(systemName: "hand.point.right.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .offset(x: offset, y: -55)
                    .onAppear {
                        withAnimation(.spring().repeatForever()) {
                            offset = -80
                        }
                    }
            }
        }
    }
}

struct SecondInstructionSetupView_Previews: PreviewProvider {
    static var previews: some View {
        SecondInstructionSetupView()
    }
}
