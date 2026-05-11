//
//  EditPosToAvoidView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 11/16/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct EditPosToAvoidView: View {
    @ObservedObject var bmmViewModel: BMMViewModel
    @Binding var profileModal: DashboardDriver.ProfileActiveModal
    
    @State var positionsToAvoidOG: [PositionalFlagCategory]
    @State var positionsToAvoid: [PositionalFlagCategory]
    @State var positionDictOG: [PositionalFlagCategory: Bool]
    @State var positionDict: [PositionalFlagCategory: Bool]
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(R.string.localizable.editPositionsToAvoid())
                            .font(.custom("Avenir-Heavy", size: 24))
                            .foregroundColor(.charcoal3)
                        Spacer()
                        Button(action: {
                            resetAndDismiss()
                        }) {
                            Image(R.image.cross.name)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.charcoal3)
                        }
                    }
                }
                
                VStack {
                    Text(R.string.localizable.whatPositionsShouldAvoid())
                        .font(.custom("Avenir-Heavy", size: 24))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.charcoal)
                }
                .padding(.trailing, 56)
            }
            .padding()
            VStack(spacing: 0) {
                ForEach(positionsToAvoid) { flag in
                    BindedRadioBtn(.simpleImage(title: flag.description,
                                                image: flag.imageStr),
                                   binding: $positionDict[flag]) { isOn in
                        positionDict[flag] = isOn
                    }
                }
            }
            .frame(maxWidth: .infinity)
            Spacer()
            VStack(spacing: 16) {
                Button(action: {
                    bmmViewModel.positionsToAvoid = positionDict.filter { $1 == true }.map { $0.0 }
                    saveAndDismiss()
                }, label: {
                    Text(R.string.localizable.save())
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(FlatButtonStyle(.primary()))
                Button(action: {
                    resetAndDismiss()
                }, label: {
                    Text(R.string.localizable.cancel())
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(FlatButtonStyle(.clear()))
            }
            .padding()
        }
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1),
                        radius: 2,
                        x: 0,
                        y: 0)
        )
    }
    
    // MARK: - Init
    init(viewModel: BMMViewModel, flow: Binding<DashboardDriver.ProfileActiveModal>) {
        var newDict: [PositionalFlagCategory: Bool] = [.supine: false, .left: false, .right: false]
        viewModel.positionsToAvoid.forEach { newDict[$0] = true }
        
        _positionDict = State(wrappedValue: newDict)
        _positionDictOG = _positionDict
        self.bmmViewModel = viewModel
        _positionsToAvoid = State(wrappedValue: [.left, .supine, .right])
        _positionsToAvoidOG = _positionsToAvoid
        _profileModal = flow
    }
}

private extension EditPosToAvoidView {
    func resetAndDismiss() {
        positionDict = positionDictOG
        positionsToAvoid = positionsToAvoidOG
        withAnimation(.spring().speed(1.3)) {
            profileModal = .none
        }
    }
    func saveAndDismiss() {
        positionDictOG = positionDict
        positionsToAvoidOG = positionsToAvoid
        withAnimation(.spring().speed(1.3)) {
            profileModal = .none
        }
    }
}

struct EditPosToAvoidView_Previews: PreviewProvider {
    static var previews: some View {
        EditPosToAvoidView(viewModel: BMMViewModel(), flow: .constant(.posToAvoid))
    }
}
