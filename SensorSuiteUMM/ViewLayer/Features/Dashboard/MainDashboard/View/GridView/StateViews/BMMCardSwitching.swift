//
//  BMMCardSwitching.swift
//  SensorSuiteUMM
//
//  Created by Vadym Riznychok on 4/21/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMCardSwitching: View {
    let bmmData: BMMCardData

    var body: some View {
        GeometryReader { geo in
            let aspectRatio = geo.size.width / 247.0
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(bmmData.roomBed ?? "Unknown")
                            .font(.custom("Avenir-Heavy", size: aspectRatio * 20))
							.lineLimit(1)
							.truncationMode(.tail)
                            .foregroundColor(.charcoal1)
                    }
                    Spacer()
                    Text(bmmData.patientState?.toString().uppercased() ?? "Unknown")
                        .font(.custom("Avenir-Heavy", size: aspectRatio * 13))
                        .conditionalModifier(bmmData.patientState == .swappingPatch || bmmData.patientState == .swappingSensor) {
                            $0.capsuleCard(.action)
                        }
                        .conditionalModifier(bmmData.patientState != .swappingPatch && bmmData.patientState != .swappingSensor) {
                            $0.capsuleCard(alertLevel: bmmData.currentAlert)
                        }
                }
                if bmmData.patientState == .swappingPatch || bmmData.patientState == .swappingSensor {
                    Image(R.image.swapping.name)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    Image(bmmData.targetPos?.imageStr ?? PositionalFlagCategory.other.imageStr)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geo.size.width * 0.518, height: geo.size.height * 0.124)
                        .grayscale(bmmData.shouldGrayOut ? 0.99 : 0)
                }
                VStack(spacing: -6) {
                    if bmmData.patientState == .swappingPatch || bmmData.patientState == .swappingSensor {
                        VStack {
                            Text("+" + bmmData.swappingTimeStr)
                                .font(.custom("Avenir-Heavy", size: aspectRatio * 16))
                                .foregroundColor(bmmData.currentAlert.primaryTextColor)
                            Text(bmmData.swappingType)
                                .font(.custom("Avenir-Heavy", size: aspectRatio * 16))
                                .foregroundColor(bmmData.currentAlert.primaryTextColor)
                        }
                    } else if bmmData.patientState == .paused {
                        Text(bmmData.pausedTimeStr)
                            .font(.custom("Avenir-Heavy", size: aspectRatio * 16))
                            .foregroundColor(bmmData.currentAlert.primaryTextColor)
                    } else {
                        Text((bmmData.isOverdue ? "+" : "") + bmmData.timeRemainingStr)
                            .font(.custom("Avenir-Heavy", size: aspectRatio * 16))
                            .foregroundColor(bmmData.currentAlert.primaryTextColor)
                    }
                    if bmmData.patientState != .swappingPatch 
                        && bmmData.patientState != .swappingSensor
                        && bmmData.sensorState != .disconnected
                        && bmmData.bmmState != .disconnected
                        && bmmData.patientState != .paused {
                        Text(bmmData.isOverdue ? R.string.localizable.over() : R.string.localizable.remaining())
                            .font(.custom("Avenir", size: aspectRatio * 16))
                            .foregroundColor(bmmData.currentAlert.primaryTextColor)
                    }
                }
                .grayscale((bmmData.shouldGrayOut && bmmData.patientState != .paused) ? 0.99 : 0)
                Spacer()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                          alignment: .center,
                          spacing: 10,
                          pinnedViews: [],
                          content: {
                    VStack(spacing: 6) {
                        Text(bmmData.currentPos?.abbreviation ?? "U")
                            .background(
                                Circle()
                                    .fill(Color.green5)
                                    .frame(width: aspectRatio * 30, height: aspectRatio * 30)
                            )
                            .font(.custom("Avenir", size: aspectRatio * 16))
                            .foregroundColor(.green1)
                        Text("Current")
                            .font(.custom("Avenir", size: aspectRatio * 12))
                            .foregroundColor(.charcoal1)
                    }

                    VStack(spacing: 6) {
                        Text(bmmData.targetPos?.abbreviation ?? "U")
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.416, green: 0.294, blue: 0.904),
                                                Color(red: 0.294, green: 0.587, blue: 0.904), 
                                            ]),
                                            startPoint: UnitPoint(x: 0.25, y: 0.5),
                                            endPoint: UnitPoint(x: 0.75, y: 0.5)))
                                    .frame(width: aspectRatio * 30, height: aspectRatio * 30)
                            )
                            .font(.custom("Avenir", size: aspectRatio * 16))
                            .foregroundColor(.white)
                        Text("Target")
                            .font(.custom("Avenir", size: aspectRatio * 12))
                            .foregroundColor(.charcoal1)
                    }

                    VStack(spacing: 6) {
                        Text(bmmData.nextPos.abbreviation)
                            .background(
                                Circle()
                                    .fill(Color.charcoal5)
                                    .frame(width: aspectRatio * 30, height: aspectRatio * 30)
                            )
                            .font(.custom("Avenir", size: aspectRatio * 16))
                            .foregroundColor(bmmData.positionsToAvoid.contains(bmmData.nextPos) ? .red2 : .charcoal3)
                        Text("Next")
                            .font(.custom("Avenir", size: aspectRatio * 12))
                            .foregroundColor(.charcoal1)
                    }
                })
                .padding(.horizontal, aspectRatio * 24)
                .grayscale(bmmData.shouldGrayOut ? 0.99 : 0)
                RollPitchVisualizations(bmmData: bmmData, rollDegree: bmmData.rollAngle, pitchDegree: bmmData.pitchAngle)
                    .grayscale(bmmData.shouldGrayOut ? 0.99 : 0)
            }
            .padding(.all, aspectRatio * 12)
        }
    }
}

struct BMMCardSwitching_Previews: PreviewProvider {
    static var previews: some View {
        BMMCardSwitching(bmmData: BMMViewModel().cardData)
    }
}
