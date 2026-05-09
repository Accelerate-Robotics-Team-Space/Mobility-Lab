//
//  BMMInfoView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 11/1/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dashboardDriver: DashboardDriver
    @ObservedObject var bmmViewModel: BMMViewModel
    
    @State private var rollDegree: Double = 0.0
    @State private var pitchDegree: Double = 0.0

    @State var selectedDate = Date()
    @State var showDatePicker = false

    private var isOldestDate: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: bmmViewModel.sessionStartDate)
    }
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                    .frame(height: 95)
                ZStack {
                    Color(.white)
                        .cornerRadius(20)
                        .padding(.bottom, -30)
                    VStack(spacing: 0, content: {
                        ScrollView(showsIndicators: false) {
                            VStack {
                                BMMDetailsDateSelectionView(bmmViewModel: bmmViewModel, selectedDate: $selectedDate, showDatePicker: $showDatePicker)
                                BMMDetailsPatientPositionView(bmmViewModel: bmmViewModel, rollDegree: $rollDegree, pitchDegree: $pitchDegree)
                                    .grayscale(bmmViewModel.cardData.shouldGrayOut ? 0.99 : 0)
                                BMMDetailsSessionStateView(bmmViewModel: bmmViewModel, selectedDate: $selectedDate)
                                BMMDetailsAnalyticsView(bmmViewModel: bmmViewModel)
                            }
                            .padding()
                        }
                        VStack {
                            Text(DeviceConstants.getEMDBuildInfoStr())
                                .textStyle(.overline, color: .silver)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 16)
                    })
                }
            }
            VStack {
                Spacer()
                    .frame(height: 95)
                HStack(alignment: .top) {
                    Spacer()
                    Button {
                        dashboardDriver.currentBMM = nil
                        dismiss()
                    } label: {
                        Image(R.image.cross.name)
                            .resizable()
                            .frame(width: 18, height: 18)
                            .contentShape(Rectangle())
                    }
                    .tint(.clear)
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
            if showDatePicker {
                DatePickerWithButtons(showDatePicker: $showDatePicker,
                                      selectedDate: $selectedDate, 
                                      minimumDate: bmmViewModel.sessionStartDate)
                    .transition(.opacity)
            }
        }
        .onChange(of: selectedDate, perform: { _ in
            bmmViewModel.isShowingTodaysAnalyics = selectedDate.isToday
            bmmViewModel.loadAnalyticsData(date: selectedDate, cleanData: true)
            showDatePicker = false
        })
        .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height
                
                if abs(horizontalAmount) > abs(verticalAmount) && horizontalAmount < 0 {
                    if !selectedDate.isToday {
                        withAnimation {
                            selectedDate = Calendar.current.date(byAdding: DateComponents(day: 1), to: selectedDate) ?? Date()
                        }
                    }
                } else if abs(horizontalAmount) > abs(verticalAmount) && horizontalAmount >= 0 {
                    if !isOldestDate {
                        withAnimation {
                            selectedDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: selectedDate) ?? Date()
                        }
                    }
                }
            })
        .onAppear {
            bmmViewModel.updateAlertLevel()
        }
    }
}

struct DatePickerWithButtons: View {
    @Binding var showDatePicker: Bool
    @Binding var selectedDate: Date
    var minimumDate: Date

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showDatePicker = false
                }
            VStack {
                DatePicker(selection: $selectedDate,
                           in: minimumDate...Date(),
                           displayedComponents: [.date],
                           label: {
                    Text("")
                })
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

struct BMMInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BMMInfoView(bmmViewModel: BMMViewModel(id: "ID", deviceId: "ALT001", unit: "ICU", roomBed: "B123-A", bmmState: .connected,
                                               sensorState: .connected, patientState: .active,
                                               timeRemaining: TimeInterval(2000), turnProtocol: "", complianceAngle: 0, currentPos: .left, targetPos: .left,
                                               rollAngle: 43.6, pitchAngle: 32.5, batteryPercentage: 42,
                                               positionsToAvoid: [], patientDetailsViewModel: .init(id: "id"), isStatic: true))
        .environmentObject(DashboardDriver())
    }
}
