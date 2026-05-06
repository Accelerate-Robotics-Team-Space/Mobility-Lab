//
//  FlexibleSheet.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/31/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct FlexibleSheet<Content: View>: View {
    let content: () -> Content
    var height: CGFloat

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                VStack {
                    VStack {}
                    .frame(width: geo.size.width, height: geo.size.height - height)
                    .background(Color.black.opacity(0.1))
                }
                content()
                    .frame(height: height)
            }
        }
        .ignoresSafeArea()
    }
    
    init(height: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.height = height
    }
}

struct FlexibleSheet_Previews: PreviewProvider {
    static var previews: some View {
        FlexibleSheet(height: 200.0) {
            VStack {
                Text("Hello World")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 25.0, style: .continuous))
        }
        .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPadAirUMM()))
    }
}
