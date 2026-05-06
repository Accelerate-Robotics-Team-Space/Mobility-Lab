//
//  BottomSheetView.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/18/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BottomSheetView<Content: View>: View {
    @Binding var isOpen: Bool
    
    private let maxHeight: CGFloat
    private let minHeight: CGFloat
    private let content: Content
    private let corner: CGFloat = 12
    
    var body: some View {
        content
            .background(Color.white)
            .offset(y: offset)
            .opacity(isOpen ? 1 : 0)
    }
    
    init(isOpen: Binding<Bool>, maxHeight: CGFloat, @ViewBuilder content: () -> Content) {
        self.minHeight = 0
        self.maxHeight = maxHeight
        self.content = content()
        self._isOpen = isOpen
    }
    
    private var offset: CGFloat {
        isOpen ? 0 : maxHeight - minHeight
    }
}

struct BottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geo in
            ZStack {
                Button(action: {}, label: {
                    Text("Button")
                })
                
                BottomSheetView(isOpen: .constant(true), maxHeight: geo.size.height * 0.7) {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {}, label: {
                                Text("Done")
                                    .bold()
                                    .font(.custom("Avenir", size: 16))
                                    .foregroundColor(Color.charcoal)
                            })
                            .padding()
                        }
                        
                        Form {
                            Text("Add")
                            Text("Some")
                            Text("Content")
                        }
                    }
                }
            }
        }
    }
}
