//
//  ThirdInstructionSetupView.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 12/7/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ThirdInstructionSetupView: View {
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        VStack {
            Text("Click \"Begin Session\" on Atlas sensor screen")
                .bold()
                .foregroundColor(.charcoal1)
            Text(R.string.localizable.pleasePairAWearable())
            ZStack {
                Image(R.image.beginSession.name)
                ZStack {
                    Image(systemName: "hand.tap.fill")
                        .frame(width: 30, height: 30)
                        .scaleEffect(scale)
                        .foregroundColor(.white)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2).repeatForever()) {
                                scale = 1
                            }
                        }
                }
                .offset(x: 50, y: 50)
            }
        }
    }
}

struct ThirdInstructionSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ThirdInstructionSetupView()
    }
}
