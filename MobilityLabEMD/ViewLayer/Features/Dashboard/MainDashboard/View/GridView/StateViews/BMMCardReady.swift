//
//  BMMCardReady.swift
//  MobilityLabEMD
//
//  Created by Vadym Riznychok on 4/21/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMCardReady: View {
    let bmmData: BMMCardData

    var body: some View {
        GeometryReader { geo in
            let aspectRatio = geo.size.width / 247.0
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(bmmData.roomBed ?? "Unknown")
                            .font(.custom("Avenir-Heavy", size: aspectRatio * 20))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(.charcoal1)
                    }
                    Spacer()
                    Text("READY")
                        .font(.custom("Avenir-Heavy", size: aspectRatio * 13))
                        .capsuleCard(alertLevel: .none)
                }
                Spacer()
                Image(bmmData.targetPos?.imageStr ?? PositionalFlagCategory.other.imageStr)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width * 0.518, height: geo.size.height * 0.124)
                    .padding(.vertical)
                    .grayscale(0.99)
                Spacer(minLength: 20)

                RollPitchVisualizations(bmmData: bmmData, rollDegree: bmmData.rollAngle, pitchDegree: bmmData.pitchAngle)
                if let room = bmmData.lastSeen?.roomBedNumber, !room.isEmpty {
                    Text("Last seen in \(room)")
                        .font(.custom("Avenir-Roman", size: aspectRatio * 16))
                        .foregroundColor(.charcoal3)
                }
            }
            .padding(.all, aspectRatio * 12)
        }
    }
}

struct BMMCardReady_Previews: PreviewProvider {
    static var previews: some View {
        BMMCardReady(bmmData: BMMViewModel().cardData)
    }
}
