//
//  DashboardSettingPositionsToAvoidView.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 3/8/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct DashboardSettingPositionsToAvoidView: View {
    @Binding var patientProfileFlow: ProfileDriver.ProfileActiveModal?
    
    @State var positionsToAvoidOG: [PositionalFlagCategory]
    @State var positionsToAvoid: [PositionalFlagCategory]
    @State var positionDictOG: [PositionalFlagCategory: Bool]
    @State var positionDict: [PositionalFlagCategory: Bool]

    private let currentTarget: PositionalFlagCategory?
    @StateObject private var positionsToAvoidDriver = PositionsToAvoidDriver()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        editPositionsButton

                        VStack {
                            whichPositionsText
                        }
                        .padding(.trailing, 56)
                    }
                    .padding()

                    Spacer()
                    
                    positionsList

                    VStack { }
                    .frame(height: 16)
                    VStack(spacing: 16) {
                        saveButton
                    }
                    .padding()
                    .padding(.bottom, geo.safeAreaInsets.bottom)
                }
                .background(backgroundView)
            }
            .padding(.bottom, -geo.safeAreaInsets.bottom)
            .background(Color.white.opacity(0.1))
        }
    }

    @ViewBuilder
    var editPositionsButton: some View {
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
    }

    @ViewBuilder
    var whichPositionsText: some View {
        Text(R.string.localizable.whatPositionsShouldAvoid())
            .font(.custom("Avenir-Heavy", size: 24))
            .multilineTextAlignment(.leading)
            .foregroundColor(.charcoal)
    }

    @ViewBuilder
    var positionsList: some View {
        VStack(spacing: 0) {
            ForEach(positionsToAvoid) { flag in
                BindedRadioBtn(
                    .simpleImage(
                        title: flag.description,
                        image: flag.imageStr
                    ),
                    binding: $positionDict[flag]
                ) { isOn in
                    positionDict.keys.forEach { positionDict[$0] = false }
                    positionDict[flag] = isOn
                }
                .disabled(currentTarget == flag)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var saveButton: some View {
        Button(action: {
            positionsToAvoidDriver.updatePositionsToAvoid(newPostionsToAvoid: positionDict) {
                saveAndDismiss()
            }
        }, label: {
            Text(R.string.localizable.save())
                .frame(maxWidth: .infinity)
        })
        .altBtnIndigo()
        .contentShape(Rectangle())
        Button(action: {
            resetAndDismiss()
        }, label: {
            Text(R.string.localizable.cancel())
                .frame(maxWidth: .infinity)
        })
        .buttonStyle(FlatButtonStyle(.clear()))
        .contentShape(Rectangle())
    }

    @ViewBuilder
    var backgroundView: some View {
        Rectangle()
            .fill(Color.white)
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 2,
                x: 0,
                y: 0
            )
    }

    // MARK: - Init
    init(
        using manager: PatientManagerProtocol? = nil,
        flow: Binding<ProfileDriver.ProfileActiveModal?>,
        isMonitoring: Bool = false
    ) {
        var newDict: [PositionalFlagCategory: Bool] = [:]
        let patientManager = manager ?? Container.shared.patientManager.resolve()
        patientManager.turningProto.turningSequence.forEach({ newDict[$0] = false })
        patientManager.posToAvoid.forEach({ newDict[$0] = true })

        self.currentTarget = isMonitoring ? patientManager.turnTrackerInfo?.getPositionOrder(.current) : nil
        _positionDict = State(wrappedValue: newDict)
        _positionDictOG = _positionDict
        _positionsToAvoid = State(wrappedValue: patientManager.turningProto.positionsToAvoid)
        _positionsToAvoidOG = _positionsToAvoid
        _patientProfileFlow = flow
    }
}

extension DashboardSettingPositionsToAvoidView {
    private func resetAndDismiss() {
        positionDict = positionDictOG
        positionsToAvoid = positionsToAvoidOG
        withAnimation(.spring().speed(1.3)) {
            patientProfileFlow = nil
        }
    }
    private func saveAndDismiss() {
        positionDictOG = positionDict
        positionsToAvoidOG = positionsToAvoid
        withAnimation(.spring().speed(1.3)) {
            patientProfileFlow = nil
        }
    }
}

struct DashboardSettingPositionsToAvoidView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardSettingPositionsToAvoidView(flow: .constant(nil))
    }
}
