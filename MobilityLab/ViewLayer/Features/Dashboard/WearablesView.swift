//
//  WearablesView.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/8/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct WearablesView: View {
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    @EnvironmentObject var wearablesDriver: WearablesDriver
    @Binding var listOfWearables: [Wearable]
    
    @State var wearable: Wearable?
    @State var show = false
    
    var body: some View {
        ZStack {
            VStack {
                VStack {} // Used for padding
                .frame(height: 13)
                Image(R.image.atlasLiftEmblem.name)
                    .resizable()
                    .frame(width: 45, height: 45)
                ScrollView {
                    VStack {
                        ForEach(listOfWearables) { wearable in
                            Button {
                                withAnimation {
                                    self.wearablesDriver.wearable = wearable
                                    self.wearablesDriver.modal = .popup
                                }
                            } label: {
                                WearableCellView(wearable: wearable)
                                    .environmentObject(patientMonitorDriver)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct WearablesView_Previews: PreviewProvider {
    static var previews: some View {
        WearablesView(listOfWearables: .constant(Wearable.previewWearables))
    }
}
