//
//  AtlasLogoPadder.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 4/5/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AtlasLogoPadder: View {
    @StateObject private var viewModel = AtlasLogoPadderViewModel()

    var body: some View {
        Image(R.image.atlasLiftEmblem.name)
            .resizable()
            .frame(width: 45, height: 45)
            .onTapGesture(count: 2) {
                viewModel.didTapLogo()
            }
    }
}

struct AtlasLogoPadder_Previews: PreviewProvider {
    static var previews: some View {
        AtlasLogoPadder()
    }
}
