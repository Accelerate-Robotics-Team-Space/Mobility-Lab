//
//  PatientMonitorSetupView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 11/9/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PatientMonitorSetupView: View {
    @EnvironmentObject var driver: DashboardDriver
    
    @State var currentIndex = 0
    @State var tabsIndex = [0, 1, 2]
    
    // MARK: - body
    var body: some View {
        VStack(alignment: .center) {
            VStack {} // Used for padding
            .frame(height: 12)
            Image(R.image.atlasLiftEmblem.name)
                .resizable()
                .frame(width: 45, height: 45)
            Spacer()
            TabView(selection: $currentIndex) {
                ForEach(tabsIndex, id: \.self) { index in
                    if index == 0 {
                        FirstInstructionSetupView()
                    } else if index == 1 {
                        SecondInstructionSetupView()
                    } else if index == 2 {
                        ThirdInstructionSetupView()
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor = .black
                UIPageControl.appearance().pageIndicatorTintColor = .gray
            }
            Spacer()
        }
    }
}

// MARK: - Preview
struct PatientMonitorSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PatientMonitorSetupView()
    }
}
