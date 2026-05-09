//
//  AnalyticsView.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 11/9/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var dashboardDriver: DashboardDriver
    @StateObject private var analyticsDriver: AnalyticsDriver

    @State private var savedDate: Date?
    @State private var showDatePicker = false

    init() {
        self._analyticsDriver = StateObject(wrappedValue: AnalyticsDriver())
    }

    var body: some View {
        ZStack {
            VStack {
                VStack {} // Used for padding
                    .frame(height: 13)
                Image(R.image.atlasLiftEmblem.name)
                    .resizable()
                    .frame(width: 45, height: 45)
                VStack {
                    HStack {
                        Button {
                            analyticsDriver.goBackward()
                        } label: {
                            Image(R.image.arrowRight.name)
                                .rotationEffect(Angle(degrees: 180))
                        }
                        .opacity(analyticsDriver.isFirstDay ? 0.2 : 1)
                        .disabled(analyticsDriver.isFirstDay)
                        Spacer()
                        HStack {
                            Button {
                                showDatePicker = true
                            } label: {
                                Image(R.image.calendar.name)
                            }
                            .frame(width: 21, height: 21)
                            if analyticsDriver.isToday {
                                Text("Today")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.charcoal1)
                            } else {
                                Text(analyticsDriver.selectedDate, style: .date)
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.charcoal1)
                            }
                        }
                        Spacer()
                        Button {
                            analyticsDriver.goForward()
                        } label: {
                            Image(R.image.arrowRight.name)
                        }
                        .opacity(analyticsDriver.isToday ? 0.2 : 1)
                        .disabled(analyticsDriver.isToday)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 8)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .onAppear {
                    analyticsDriver.selectedDate = Date()
                }
                AnalyticsDayView(logs: Array(analyticsDriver.timeLineDict.values))
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .padding(.top, 35)
                AnalyticsCumulativeCellView(
                    dict: analyticsDriver.positionDurations,
                    pausedDuration: analyticsDriver.pausedDuration,
                    wrongDuration: analyticsDriver.wrongDuration
                )
                .frame(maxWidth: .infinity)
            }
            DatePickerWithButtons(
                driver: analyticsDriver,
                showDatePicker: $showDatePicker,
                selectedDate: $analyticsDriver.selectedDate
            )
            .opacity(showDatePicker ? 1 : 0)
            .allowsHitTesting(showDatePicker)
            .animation(.none, value: showDatePicker)

        }
        .onChange(of: analyticsDriver.selectedDate, perform: { _ in
            analyticsDriver.updateUI()
            showDatePicker = false
        })
        .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height
                
                if abs(horizontalAmount) > abs(verticalAmount) && horizontalAmount < 0 {
                    withAnimation {
                        if !analyticsDriver.isToday {
                            analyticsDriver.goForward()
                        }
                    }
                } else if abs(horizontalAmount) > abs(verticalAmount) && horizontalAmount >= 0 {
                    withAnimation {
                        if !analyticsDriver.isFirstDay {
                            analyticsDriver.goBackward()
                        }
                    }
                }
            })
    }
}

struct DatePickerWithButtons: View {
    @ObservedObject var driver: AnalyticsDriver
    
    @Binding var showDatePicker: Bool
    @Binding var selectedDate: Date
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showDatePicker = false
                }
            VStack {
                DatePicker("AnalyticsDatePicker",
                           selection: $selectedDate,
                           in: driver.firstDay...Date(),
                           displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .frame(width: 320)
            }
            .padding(.horizontal, 16)
            .background(
                Color.white
                    .cornerRadius(8)
            )
        }
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environmentObject(AnalyticsDriver())
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
    }
}
