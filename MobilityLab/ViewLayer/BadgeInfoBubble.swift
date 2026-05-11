//
//  BadgeInfoBubble.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 3/21/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BadgeInfoBubble: View {
    private let formatter = DateComponentsFormatter()
    
    private(set) var activity: ActivityStartEnd
    
    private var description: String {
        if activity.isPause {
            return "Paused Session"
        } else {
            return activity.targetPosition.description
        }
    }
    
    private var startTimeString: String {
        return formatter.string(from: activity.startTime)!
    }
    private var endTimeString: String {
        return formatter.string(from: activity.endTime)!
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(description)")
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.white)
            Text("\(startTimeString) - \(endTimeString)")
                .font(.custom("Avenir-Roman", size: 12))
                .foregroundColor(.charcoal3)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.charcoal1)
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                Rectangle()
                    .fill(Color.charcoal1)
                    .rotationEffect(.degrees(45))
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: 8)
                    .offset(y: -4)
            }
        )
    }
    
    // MARK: - Init
    init(activity: ActivityStartEnd) {
        formatter.allowedUnits = [.hour, .minute]
        
        self.activity = activity
    }
}

struct BadgeInfoBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BadgeInfoBubble(
                activity: ActivityStartEnd(
                    startDate: Date().startOfDay.addingTimeInterval(6 * 60 * 60),
                    endDate: Date().startOfDay.addingTimeInterval(10 * 60 * 60),
                    actualPosition: .right,
                    targetPosition: .supine,
                    startTime: 12.8 * 60 * 60,
                    endTime: 12.92 * 60 * 60,
                    isPause: false
                )
            )
        }
    }
}
