//
//  BMMCardUnassigned.swift
//  SensorSuiteUMM
//
//  Created by Vadym Riznychok on 4/21/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMCardUnassigned: View {
    var body: some View {
        GeometryReader { geo in
            let aspectRatio = geo.size.width / 247.0
            VStack {
                Text("UNASSIGNED")
                    .font(.custom("Avenir-Heavy", size: aspectRatio * 13))
					.lineLimit(1)
					.truncationMode(.tail)
                    .capsuleCard(alertLevel: .none)
                Spacer()
                Image(R.image.bmmPhoneIconLarge.name)
                    .resizable()
                    .frame(width: 51, height: 96)
                Spacer()
                Text("Unknown location")
                    .font(.custom("Avenir-Roman", size: aspectRatio * 16))
                    .foregroundColor(.charcoal3)
            }
            .frame(width: geo.size.width - (2 * aspectRatio * 12))
            .padding(.all, aspectRatio * 12)
        }
    }
}

struct BMMCardUnassigned_Previews: PreviewProvider {
    static var previews: some View {
        BMMCardUnassigned()
    }
}
