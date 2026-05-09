//
//  BMMCardNoSession.swift
//  MobilityLabEMD
//
//  Created by Vadym Riznychok on 4/21/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMCardNoSession: View {
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
                    Text("NO SESSION")
                        .font(.custom("Avenir-Heavy", size: aspectRatio * 13))
                        .capsuleCard(alertLevel: .none)
                }
                Spacer()
                Image(R.image.bmmPhoneIconLarge.name)
                    .resizable()
                    .frame(width: 51, height: 96)
                Spacer()
                if let room = bmmData.lastSeen?.roomBedNumber, !room.isEmpty {
                    Text("Last seen in \(room)")
                        .font(.custom("Avenir-Roman", size: aspectRatio * 16))
                        .foregroundColor(.charcoal3)
                } else {
                    Text("No active patient session")
                        .font(.custom("Avenir-Roman", size: aspectRatio * 16))
                        .foregroundColor(.charcoal3)
                }
            }
            .padding(.all, aspectRatio * 12)
        }
    }
}

struct BMMCardNoSession_Previews: PreviewProvider {
    static var previews: some View {
        BMMCardNoSession(bmmData: BMMViewModel().cardData)
    }
}
