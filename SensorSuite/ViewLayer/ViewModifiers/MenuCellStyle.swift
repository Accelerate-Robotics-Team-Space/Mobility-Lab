//
//  MenuCellStyle.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/13/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct MenuCellStyle: ViewModifier {
    func body(content: Content) -> some View {
        VStack (alignment: .center) {
            content
                .font(.custom("Avenir", size: 16))
                .frame(height: 52, alignment: .center)
        }
        .frame(alignment: .center)
        .multilineTextAlignment(.center)
    }
}

extension View {
    func menuCellStyle() -> some View {
        self.modifier(MenuCellStyle())
    }
}

struct MenuCellStyle_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            Section(header:
                        Text("Test Section")
                        .textStyle(.body2)
            ) {
                Text("List Item 1")
                    .menuCellStyle()
                
                Text("List Item 2")
                    .menuCellStyle()
            }
            
            Section(header:
                        Text("Another Test Section")
                        .textStyle(.body2)
            ) {
                Text("List Item 3")
                    .menuCellStyle()
            }
        }
    }
}
