//
//  PositionHistoryCellView.swift
//  SensorSuite
//
//  Created by Josh Franco on 12/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PositionHistorySegmentView: View {
    var isFirstSegment: Bool
    var position: PositionalFlags
    var startDate: Date
    
    var body: some View {
        VStack(spacing: 0) {
            Line()
                .stroke(style: StrokeStyle(lineWidth: 2,
                                           dash: isFirstSegment ? [10] : []))
                .frame(height: 1)
                .foregroundColor(.aqua)
                .overlay(
                    HStack {
                        Spacer()
                        Text(isFirstSegment ? "Now" : startDate.shortFormatted)
                            .background(Color.white)
                    }
                )
            ZStack {
                HStack {
                    Rectangle()
                        .foregroundColor(Color(red: Double.random(in: 0...1),
                                               green: Double.random(in: 0...1),
                                               blue: Double.random(in: 0...1)))
                        .frame(width: 165, height: 100)
                    
                    Spacer()
                }
            }
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        
                        Text(position.description)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            )
        }
    }
    
    init(position: PositionalFlags, startDate: Date, isFirstSegment: Bool = false) {
        self.position = position
        self.startDate = startDate
        self.isFirstSegment = isFirstSegment
    }
}

struct PositionHistoryCellView: View {
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                Text("Position History")
                    .textStyle(.header4)
                
                Spacer()
                
                R.image.history.image
                    .renderingMode(.template)
                    .foregroundColor(.charcoal)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                PositionHistorySegmentView(position: .fowlers,
                                           startDate: Date(),
                                           isFirstSegment: true)
                
                PositionHistorySegmentView(position: .leftLateral,
                                           startDate: Date().addingTimeInterval(-500))
                
                PositionHistorySegmentView(position: .rightLateral,
                                           startDate: Date().addingTimeInterval(-1000))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(5)
        .shadow(radius: 5)
    }
}

struct PositionHistoryCellView_Previews: PreviewProvider {
    static var previews: some View {
        PositionHistoryCellView()
    }
}
