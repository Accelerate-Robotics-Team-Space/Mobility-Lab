//
//  PosToAvoidProfileCell.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/16/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PosToAvoidProfileCell: View {
    @Binding var modal: ProfileDriver.ProfileActiveModal?
    
    private let posToAvoid: [PositionalFlagCategory]
    
    var body: some View {
        VStack {
            HStack {
                Image(R.image.patientPositionsToAvoidIcon.name)
                Text("Positions to avoid")
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(.charcoal1)
                Spacer()
                Button {
                    withAnimation(.spring().speed(0.9)) {
                        modal = .posToAvoid
                    }
                } label: {
                    Text(R.string.localizable.edit().uppercased())
                        .foregroundColor(.white)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.black.opacity(0.4))
                )
            }
            if posToAvoid.isEmpty {
                R.string.localizable.none.text
                    .textStyle(.body2)
            } else {
                VStack {
                    ForEach(posToAvoid) { cat in
                        Button {
                            withAnimation(.spring().speed(0.9)) {
                                modal = .posToAvoid
                            }
                        } label: {
                            HStack {
                                Text(cat.description)
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.charcoal1)
                                Spacer()
                                Image(cat.imageStr)
                                    .resizable()
                                    .frame(width: 48, height: 13)
                            }
                        }
                        if cat != posToAvoid.last {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.red5)
        .cornerRadius(16)
    }
    
    // MARK: - Init
    init(for posToAvoid: [PositionalFlagCategory], modal: Binding<ProfileDriver.ProfileActiveModal?>) {
        self.posToAvoid = posToAvoid
        self._modal = modal
    }
}

struct PosToAvoidProfileCell_Previews: PreviewProvider {
    static var previews: some View {
        PosToAvoidProfileCell(for: [.left, .supine], modal: .constant(nil))
    }
}
