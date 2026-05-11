//
//  View+Extensions.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/26/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Combine
import SwiftUI

extension View {
    func conditionalModifier<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
         if conditional {
             return AnyView(content(self))
         } else {
             return AnyView(self)
         }
     }

    func defaultShadows() -> some View {
        self.shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.1), radius: 2, x: 0, y: 0)
        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.05), radius: 12, x: 0, y: 0)
        .shadow(color: Color(red: 1, green: 1, blue: 1, opacity: 1), radius: 8, x: 0, y: 0)
    }
}

public extension View {
    func presentModal(isPresented: Binding<Bool>,
                      content: @escaping () -> some View) -> some View {
        if isPresented.wrappedValue {
            let viewController = UIHostingController(rootView: content())
            viewController.modalPresentationStyle = .overFullScreen
            viewController.modalTransitionStyle = .coverVertical
            viewController.view.backgroundColor = .black.withAlphaComponent(0.4)
            UIApplication.shared.topMostController()?.present(viewController, animated: true, completion: nil)
        }
        return self
    }
}
