//
//  ActivityBadge.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 11/1/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ActivityBadge: View {
    var activity: ActivitiesViewModel
    var multiplier: CGFloat
    @Binding var currentId: Int64
    
    var length: CGFloat {
        (activity.endTime - activity.startTime) / 60 / 60 * (7 * multiplier + 4.0) * 3
    }
    
    var badgeColor: Color {
        if activity.isPause {
            return .charcoal4
        } else {
            if activity.isWrong {
                return .red4
            } else {
                return .aqua4
            }
        }
    }
    
    var body: some View {
        VStack {
            BadgeInfoBubble(activity: activity)
                .opacity(currentId == activity.id ? 1 : 0)
            Button {
                if currentId == activity.id {
                    currentId = -1
                } else {
                    currentId = activity.id
                }
            } label: {
                if !activity.isPause {
                    HStack {
                        Image(activity.position.imageStr)
                            .resizable()
                            .frame(width: 31.87, height: 6.36)
                            .offset(x: 4)
                    }
                    Spacer()
                }
            }
            .frame(width: length < 40 ? 40 : length, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(badgeColor)
                    .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
}

struct ActivityBadge_Previews: PreviewProvider {
    static var previews: some View {
        ActivityBadge(activity: ActivitiesViewModel(id: 1,
                                                    position: .left,
                                                    startTime: 5 * 60 * 60,
                                                    endTime: 5.05 * 60 * 60,
                                                    isWrong: false,
                                                    isPause: false),
                      multiplier: 2.0,
                      currentId: .constant(1))
    }
}
