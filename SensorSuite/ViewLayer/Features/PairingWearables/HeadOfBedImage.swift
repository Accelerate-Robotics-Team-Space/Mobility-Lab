//
//  HeadOfBedImage.swift
//  SensorSuite
//
//  Created by Deepika Ramesh on 12/22/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct HeadOfBedImage: View {
    var angle: Double
    var target: PositionalFlagCategory?

    var body: some View {
        if angle < 0 {
            Image(R.image.zeroDegree.name)
                .resizable()
                .scaledToFit()
                .rotationEffect(Angle(degrees: -angle), anchor: UnitPoint(x: 0.5, y: 0.8))
        } else {
            Image(HeadOfBedDegreeImageMapper.imageName(angle))
            .resizable()
            .scaledToFit()
        }
    }
}

struct HeadOfBedImage_Previews: PreviewProvider {
    static var previews: some View {
        HeadOfBedImage(angle: 30, target: .supine)
    }
}
