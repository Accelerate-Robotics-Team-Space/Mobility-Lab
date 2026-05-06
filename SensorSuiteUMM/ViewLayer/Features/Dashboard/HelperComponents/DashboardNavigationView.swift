//
//  DashboardNavigationView.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 11/3/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DashboardNavigationView: View {
    @Binding var showSideView: Bool
    @Binding var displayList: Bool
    @Binding var currentSort: DashboardDriver.SortedBy
    @Binding var expandSorting: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top, content: {
                HStack {
                    Spacer()
                        .frame(width: ((geo.size.width - 35.0) / 2))
                    Image(R.image.atlasLiftEmblem.name)
                        .resizable()
                        .onTapGesture(count: 3) {
                            showSideView.toggle()
                        }
                        .frame(width: 35, height: 35)
                    Spacer()
                    Toggle(isOn: $displayList, label: {})
                        .toggleStyle(CustomToggleStyle())
                        .onChange(of: displayList) { newState in
                            displayList = newState
                        }
                    Spacer()
                        .frame(width: 16)
                }
                HStack {
                    Spacer()
                        .frame(width: 16)
                    DashboardSortButton(currentSort: $currentSort, expandSorting: $expandSorting)
                    Spacer()
                }
            })
        }
    }
}

struct DashboardNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardNavigationView(showSideView: .constant(false), displayList: .constant(false),
                                currentSort: .constant(.roomBed), expandSorting: .constant(false))
    }
}
