//
//  CurrentTargetNextCombo.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 11/8/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct CurrentTargetNextCombo: View {
    let bmmData: BMMCardData

    var body: some View {
        HStack(spacing: 58) {
            Text(bmmData.currentPos?.abbreviation ?? "U")
                .background(
                    Circle()
                        .fill(Color.green5)
                        .frame(width: 30, height: 30)
                )
                .font(.custom("Avenir", size: 16))
                .foregroundColor(.green1)
            Text(bmmData.targetPos?.abbreviation ?? "U")
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors:
                                                    [
                                                        Color(red: 0.416, green: 0.294, blue: 0.904),
                                                        Color(red: 0.294, green: 0.587, blue: 0.904),
                                                    ]
                                                  ),
                                startPoint: UnitPoint(x: 0.25, y: 0.5),
                                endPoint: UnitPoint(x: 0.75, y: 0.5)))
                        .frame(width: 30, height: 30)
                )
                .font(.custom("Avenir", size: 16))
                .foregroundColor(.white)
            Text(bmmData.nextPos.abbreviation)
                .background(
                    Circle()
                        .fill(Color.charcoal5)
                        .frame(width: 30, height: 30)
                )
                .font(.custom("Avenir", size: 16))
                .foregroundColor(.charcoal3)
        }
    }
}

struct CurrentTargetNextCombo_Previews: PreviewProvider {
    static var previews: some View {
        CurrentTargetNextCombo(bmmData: BMMViewModel().cardData)
    }
}
