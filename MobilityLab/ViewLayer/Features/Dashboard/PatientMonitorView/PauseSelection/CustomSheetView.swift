//
//  CustomSheetView.swift
//  MobilityLab
//
//  Created by Vadym Riznychok on 5/19/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import Combine
import SwiftUI

struct CustomSheetView<Title: View, Content: View, Cancel: View>: View {
    let title: Title
    let bodyContent: Content
    let cancelContent: Cancel

    init(@ViewBuilder title: @escaping () -> Title,
         @ViewBuilder bodyContent: @escaping () -> Content,
         @ViewBuilder cancelContent: @escaping () -> Cancel) {
        self.title = title()
        self.bodyContent = bodyContent()
        self.cancelContent = cancelContent()
    }

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            VStack(spacing: 0) {
                VStack {
                    Spacer()
                        .frame(height: 8)
                    title
                        .frame(maxWidth: .infinity)
                }
                .background(Color.gray.opacity(0.2))
                Divider()
                bodyContent
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            cancelContent
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8, corners: .allCorners)
        }
        .padding(.horizontal, 48)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom))
    }
}

public struct DialogButton<Content: View> {
    public var action: () -> Void
    public var label: Content
}

public extension View {
    func buildSheet(title: @escaping () -> some View,
                    @ButtonsResultBuilder bodyContent: @escaping () -> some View,
                    @ButtonsResultBuilder cancelContent: @escaping () -> some View) -> some View {
        return CustomSheetView(title: title, bodyContent: bodyContent, cancelContent: cancelContent)
    }

    func dialogAction(_ action: @escaping () -> Void) -> DialogButton<Self> {
        DialogButton(action: {
            action()
        }, label: self)
    }
}

@resultBuilder
public struct ButtonsResultBuilder {
    @ViewBuilder 
    public static func buildBlock<Content: View>(_ parts: DialogButton<Content>...) -> some View {
        let partsCount = parts.count
        ForEach(0..<partsCount, id: \.self) { index in
            let part = Array(parts)[index]
            let isLast = partsCount > 1 ? partsCount == (index - 1) : false
            VStack {
                Button(action: {
                    part.action()
                }) {
                    part.label
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.bottom, isLast ? 16 : 0)
                        .padding(.top, 0)
                        .contentShape(Rectangle())
                }
            }
            .buttonStyle(HeightlightedStyle())
        }
    }

    static func buildEither<Content: View>(first component: DialogButton<Content>) -> DialogButton<Content> {
        return component
    }

    static func buildEither<Content: View>(second component: DialogButton<Content>) -> DialogButton<Content> {
        return component
    }
}

private struct HeightlightedStyle: ButtonStyle {
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .background(configuration.isPressed ? Color.indigo5 : Color.clear)
  }
}
