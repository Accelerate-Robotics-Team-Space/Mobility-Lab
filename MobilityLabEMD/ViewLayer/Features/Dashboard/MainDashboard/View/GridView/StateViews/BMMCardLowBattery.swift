//
//  BMMCardLowBattery.swift
//  MobilityLabEMD
//
//  Created by Vadym Riznychok on 4/21/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMCardLowBattery: View {
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
                    Text("LOW BATTERY")
                        .font(.custom("Avenir-Heavy", size: aspectRatio * 13))
                        .capsuleCard(bmmData.isLowBatteryCritical ? .destructive : .warning)
                }
                Image(bmmData.targetPos?.imageStr ?? PositionalFlagCategory.other.imageStr)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: aspectRatio * 128, height: aspectRatio * 36)
                    .grayscale(bmmData.shouldGrayOut ? 0.99 : 0)
                VStack(spacing: -6) {
                    Text((bmmData.isOverdue ? "+" : "") + bmmData.timeRemainingStr)
                        .font(.custom("Avenir-Heavy", size: aspectRatio * 16))
                        .foregroundColor(bmmData.isOverdue ? .red1 : .charcoal1)
                    Text(bmmData.isOverdue ? R.string.localizable.over() : R.string.localizable.remaining())
                        .font(.custom("Avenir", size: aspectRatio * 16))
                        .foregroundColor(bmmData.isOverdue ? .red1 : .charcoal1)
                }
                .grayscale(bmmData.shouldGrayOut ? 0.99 : 0)
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
                            .conditionalModifier(bmmData.positionsToAvoid.contains(bmmData.nextPos)) {
                                $0.background(
                                    ZStack {
                                        Circle()
                                            .stroke(lineWidth: 1)
                                            .foregroundColor(.red2)
                                            .frame(width: aspectRatio * 30, height: aspectRatio * 30)
                                        Path { path in
                                            path.move(to: CGPoint(x: 22, y: 2))
                                            path.addLine(to: CGPoint(x: 18, y: 8))
                                            path.move(to: CGPoint(x: 6, y: 27))
                                            path.addLine(to: CGPoint(x: 11, y: 20))
                                        }
                                        .stroke(Color.red2, lineWidth: 1)
                                    }
                                )
                            }
                            .conditionalModifier(!bmmData.positionsToAvoid.contains(bmmData.nextPos)) {
                                $0.background(
                                    Circle()
                                        .fill(Color.charcoal5)
                                        .frame(width: aspectRatio * 30, height: aspectRatio * 30)
                                )
                            }
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

struct BMMCardLowBattery_Previews: PreviewProvider {
    static var previews: some View {
        BMMCardLowBattery(bmmData: BMMViewModel().cardData)
    }
}
