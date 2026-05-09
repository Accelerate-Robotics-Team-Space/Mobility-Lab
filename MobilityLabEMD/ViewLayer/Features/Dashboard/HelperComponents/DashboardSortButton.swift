//
//  DashboardSortButton.swift
//  MobilityLab BMM
//
//  Created by Vadym Riznychok on 11/3/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DashboardSortButton: View {
    @Binding var currentSort: DashboardDriver.SortedBy
    @Binding var expandSorting: Bool

    var body: some View {
        Button {
            withAnimation {
                expandSorting.toggle()
            }
        } label: {
            VStack {
                HStack {
                    Image(R.image.filter.name)
                        .resizable()
                        .frame(width: 18, height: 20)
                    Spacer()
                    Text(currentSort.name)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.black)
                    Spacer()
                    Image(R.image.arrowDown.name)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                if expandSorting {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                        Button {
                            withAnimation {
                                currentSort = .roomBed
                                expandSorting = false
                            }
                        } label: {
                            HStack {
                                Text("Room/Bed")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.black)
                                if currentSort == .roomBed {
                                    Spacer()
                                    Image(R.image.componentCheck.name)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                        }
                        Button {
                            withAnimation {
                                currentSort = .urgency
                                expandSorting = false
                            }
                        } label: {
                            HStack {
                                Text("Urgency")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.black)
                                if currentSort == .urgency {
                                    Spacer()
                                    Image(R.image.componentCheck.name)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                        }
                        Button {
                            withAnimation {
                                currentSort = .unit
                                expandSorting = false
                            }
                        } label: {
                            HStack {
                                Text("Unit")
                                    .font(.custom("Avenir-Heavy", size: 16))
                                    .foregroundColor(.black)
                                if currentSort == .unit {
                                    Spacer()
                                    Image(R.image.componentCheck.name)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .frame(width: 180)
        .buttonStyle(StaticButtonStyle())
    }

    init(currentSort: Binding<DashboardDriver.SortedBy>, expandSorting: Binding<Bool>) {
        self._currentSort = currentSort
        self._expandSorting = expandSorting
    }
}

struct StaticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct DashboardSortButton_Previews: PreviewProvider {
    static var previews: some View {
        DashboardSortButton(currentSort: .constant(.roomBed), expandSorting: .constant(false))
    }
}
