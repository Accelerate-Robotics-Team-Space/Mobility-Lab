//
//  SideMenuBMMView.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 8/1/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SideMenuBMMView: View {
    var deviceId: String
    var roomBed: String?
    var sensorId: String?
    var isAlive: Bool
    var daysLastSeen: Int

    @State private var showCopied = false

    private var roomText: String {
        if daysLastSeen > 6 {
            return "UNASSIGNED"
        } else {
            return "\(isAlive ? "Room" : "Last"): \(roomBed ?? "")"
        }
    }

    private var daysLastSeenText: String {
        guard daysLastSeen > 6 else {
            return ""
        }

        if daysLastSeen > 30 {
            return ">30 days since update"
        } else {
            return "\(daysLastSeen) days since update"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(deviceId)
                    .font(.custom("Avenir-Roman", size: 12))
                    .foregroundColor(.black)
                Spacer()
            }
            .onTapGesture {
                /// Hack to fix onLongPressGesture blocking ScrollView from scrolling.
                /// https://stackoverflow.com/questions/71281713/using-gesturelongpressgesture-break-the-scrollview
            }
            .onLongPressGesture {
                UIPasteboard.general.string = deviceId
                showCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showCopied = false
                }
            }
            HStack {
                Text(roomText)
                    .font(.custom("Avenir-Roman", size: 12))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
                if let sensorId = sensorId {
                    Text("Sensor:\(sensorId)")
                        .font(.custom("Avenir-Roman", size: 12))
                        .foregroundColor(.black)
                } else if daysLastSeen > 6 {
                    Text(daysLastSeenText)
                        .font(.custom("Avenir-Roman", size: 12))
                        .foregroundColor(.black)
                }
            }
        }
        .popover(isPresented: $showCopied, content: {
            Text("Copied!")
        })
    }
}

#Preview {
    SideMenuBMMView(deviceId: "ALT007", roomBed: "H331-1", sensorId: "BB3221FD", isAlive: true, daysLastSeen: 0)
}
