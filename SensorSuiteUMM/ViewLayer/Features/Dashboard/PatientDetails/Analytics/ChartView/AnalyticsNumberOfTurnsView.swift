//
//  AnalyticsNumberOfTurnsView.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 4/3/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsNumberOfTurnsView: View {
    @EnvironmentObject var driver: DashboardDriver
    @State var showFullTimestamp: Bool = false
    let timestamps: [TurnTimestamp]

    private var turnProtocol: TurnProtocol {
        driver.currentBMM?.turnProtocol ?? .Q2
    }
    private var timeComps: [(Int, Int)] = []
    private var timeDivision: Int {
        switch turnProtocol {
        case .Q2:
            return 11
        case .Q3:
            return 7
        case .Q4:
            return 5
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(spacing: 3) {
                Text("N° of Target\nPosition Turn")
                    .font(.custom("Avenir-Roman", size: 11))
                    .foregroundColor(.charcoal1)
                    .lineLimit(2)
                    .padding(.leading, 4)
                VStack {
                    Spacer()
                    Text("\(timestamps.count)")
                        .font(.custom("Avenir-Roman", size: 11))
                        .frame(width: 14, height: 14)
                        .foregroundColor(.white)
                        .background(Color.indigo1)
                        .cornerRadius(7)
                        .padding(.trailing, 3)
                    Spacer()
                        .frame(height: 3)
                }
            }
            .frame(width: 100, height: 38)
            VStack(spacing: 0, content: {
                ForEach((0...1), id: \.self) { hIndex in
                    if hIndex == 0 {
                        HStack(spacing: 0) {
                            ForEach((0...timeDivision), id: \.self) { vIndex in
                                HStack(alignment: .center, spacing: 0) {
                                    Spacer()
                                    ForEach((0...min(timestampCount(for: vIndex), 1)), id: \.self) { iconInd in
                                        if iconInd > 0 {
                                            Button {
                                                showFullTimestamp.toggle()
                                            } label: {
                                                Spacer()
                                                    .frame(width: 2)
                                                Image(R.image.turnCheckmark.name)
                                                    .resizable()
                                                    .frame(width: 10, height: 10)
                                                Spacer()
                                                    .frame(width: 2)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                                .foregroundColor(.clear)
                                .frame(height: 19)
                                .frame(maxWidth: .infinity)
                                .overlay(EdgeBorder(width: 1, edges: vIndex == timeDivision ? [.leading, .trailing] : [.leading])
                                    .stroke(Color.charcoal4.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .overlay(EdgeBorder(width: 1, edges: [.top])
                            .stroke(Color.charcoal4.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4])))
                    } else {
                        HStack(spacing: 0) {
                            ForEach((0...timeDivision), id: \.self) { vIndex in
                                HStack(alignment: .top) {
                                    Button {
                                        showFullTimestamp.toggle()
                                    } label: {
                                        viewForTimestamps(timestamps(for: vIndex))
                                    }
                                }
                                .foregroundColor(.clear)
                                .frame(maxWidth: .infinity, minHeight: 19)
                                .overlay(EdgeBorder(width: 1, edges: vIndex == timeDivision ? [.leading, .trailing] : [.leading])
                                    .stroke(Color.charcoal4.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .overlay(EdgeBorder(width: 1, edges: [.top, .bottom])
                            .stroke(Color.charcoal4.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4])))
                    }
                }
            })
            .frame(maxWidth: .infinity)
        }
    }

    private func timestamps(for ind: Int) -> [String] {
        let startHour = ind * turnProtocol.hoursInt
        let range = startHour...(startHour + (turnProtocol.hoursInt - 1))
        let result: [String] = timeComps
            .filter { comp in
                return range.contains(comp.0)
            }
            .compactMap { comp in
                return "\(comp.0 > 9 ? "\(comp.0)" : "0" + "\(comp.0)"):\(comp.1 > 9 ? "\(comp.1)" : "0" + "\(comp.1)")"
            }
        return result
    }

    private func timestampCount(for ind: Int) -> Int {
        let startHour = ind * turnProtocol.hoursInt
        let range = startHour...(startHour + (turnProtocol.hoursInt - 1))
        let result = timeComps.filter( { comp in
            return range.contains(comp.0)
        })
        return result.count
    }

    private func viewForTimestamps(_ timestamps: [String]) -> some View {
        VStack(spacing: 0) {
            ForEach((0...(showFullTimestamp ? max(timestamps.count - 1, 0) : 0)), id: \.self) { stampInd in
                Text(timestamps.isEmpty ? " " : timestamps[stampInd])
                    .font(.custom("Avenir-Roman", size: 12))
                    .foregroundColor(.charcoal4)
                    .frame(height: 19)
            }
            if showFullTimestamp {
                Spacer()
            }
        }
    }

    init(timestamps: [TurnTimestamp]) {
        self.timestamps = timestamps
        self.timeComps = timestamps
            .sorted(by: { $0.turnTime < $1.turnTime })
            .compactMap({ (Int($0.turnTime.timeSinceStartOfDay) / 3600, (Int($0.turnTime.timeSinceStartOfDay) % 3600) / 60) })
    }
}

#Preview {
    AnalyticsNumberOfTurnsView(timestamps: [])
}
