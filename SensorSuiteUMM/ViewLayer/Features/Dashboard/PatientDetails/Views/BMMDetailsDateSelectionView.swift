//
//  BMMDetailsDateSelectionView.swift
//  SensorSuite UMM
//
//  Created by Vadym Riznychok on 11/29/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BMMDetailsDateSelectionView: View {
    @ObservedObject var bmmViewModel: BMMViewModel
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool
    private var isOldestDate: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: bmmViewModel.sessionStartDate)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0, content: {
            Text(bmmViewModel.roomBed ?? "")
                .font(.custom("Avenir-Heavy", size: 24))
                .foregroundColor(.charcoal1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            HStack(alignment: .top) {
                Button {
                    selectedDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: selectedDate) ?? Date()
                } label: {
                    Image(R.image.arrowRight.name)
                        .rotationEffect(Angle(degrees: 180))
                }
                .opacity(!bmmViewModel.cardData.canShowPatientDetails || isOldestDate ? 0.2 : 1)
                .disabled(!bmmViewModel.cardData.canShowPatientDetails || isOldestDate)
                Spacer()
                HStack {
                    Button {
                        showDatePicker = true
                    } label: {
                        Image(R.image.calendar.name)
                    }
                    .frame(width: 21, height: 21)
                    .disabled(bmmViewModel.patientState == .noSession || bmmViewModel.patientState == .unassigned)
                    if selectedDate.isToday {
                        Text("Today")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(.charcoal1)
                    } else {
                        Text(selectedDate, style: .date)
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(.charcoal1)
                    }
                }
                Spacer()
                Button {
                    selectedDate = Calendar.current.date(byAdding: DateComponents(day: 1), to: selectedDate) ?? Date()
                } label: {
                    Image(R.image.arrowRight.name)
                }
                .opacity(!bmmViewModel.cardData.canShowPatientDetails || selectedDate.isToday ? 0.2 : 1)
                .disabled(!bmmViewModel.cardData.canShowPatientDetails || selectedDate.isToday)
            }
            .frame(width: 343)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color.white)
            .cornerRadius(100)
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .frame(maxWidth: .infinity)
            Spacer()
                .frame(maxWidth: .infinity)
        })
    }
}

struct BMMDetailsDateSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        BMMDetailsDateSelectionView(bmmViewModel: BMMViewModel(), selectedDate: .constant(Date()), showDatePicker: .constant(false))
    }
}
