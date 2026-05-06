//
//  FlexibleSheet.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 11/17/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct FlexibleSheet<Content: View>: View {
    let content: () -> Content
    var height: CGFloat
    
    init(height: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                VStack {
                    VStack {}
                    .frame(width: geo.size.width, height: geo.size.height - height)
                    .background(Color.black.opacity(0.1))
                }
                content()
                    .frame(maxHeight: height + geo.safeAreaInsets.bottom)
            }
        }
    }
}

struct FlexibleSheet_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geo in
            VStack {
                FlexibleSheet(height: geo.size.height * 0.68) {
					DashboardSettingPatientLocationView(flow: .constant(nil), patientLocationDriver: PatientLocationDriver())
                        .background(Color.black.opacity(0.1))
                }
            }
            .background(Color.red)
        }
    }
}
