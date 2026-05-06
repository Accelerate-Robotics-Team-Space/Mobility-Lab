//
//  PosToAvoidProfileCell.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 11/1/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PosToAvoidProfileCell: View {
    @ObservedObject var bmmViewModel: BMMViewModel
    
    private let posToAvoid: [PositionalFlagCategory]
    
    var body: some View {
        VStack {
            Button {
                if bmmViewModel.currentOpening != .positionsToAvoid {
                    bmmViewModel.currentOpening = .positionsToAvoid
                } else {
                    bmmViewModel.currentOpening = .none
                }
            } label: {
                HStack {
                    Image(R.image.patientPositionsToAvoidIcon.name)
                        .resizable()
                        .frame(width: 26, height: 26)
                    HStack { }
                        .frame(width: 12)
                    Text("Positions to avoid")
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Image(R.image.arrowDown.name)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(bmmViewModel.currentOpening == .positionsToAvoid ? -180 : 0))
                        .animation(.spring(), value: bmmViewModel.currentOpening)
                }
            }
            if bmmViewModel.currentOpening == .positionsToAvoid {
                VStack { }
                    .frame(height: 4)
                if !self.bmmViewModel.cardData.canShowPatientDetails || posToAvoid.isEmpty {
                    R.string.localizable.none.text
                        .textStyle(.body2)
                } else {
                    VStack {
                        ForEach(posToAvoid) { cat in
                            HStack {
                                Text(cat.description)
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.charcoal1)
                                Spacer()
                                Image(cat.imageStr)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 18)
                            }
                            if cat != posToAvoid.last {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Init
    init(bmmViewModel: BMMViewModel, for posToAvoid: [PositionalFlagCategory]) {
        self.bmmViewModel = bmmViewModel
        self.posToAvoid = posToAvoid
    }
}

struct PosToAvoidProfileCell_Previews: PreviewProvider {
    static var previews: some View {
        PosToAvoidProfileCell(bmmViewModel: BMMViewModel(),
                              for: [.left, .supine])
    }
}
