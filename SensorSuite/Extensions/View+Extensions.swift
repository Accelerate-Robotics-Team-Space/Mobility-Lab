//
//  View+Extensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/6/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

private final class PresentedHostingController<Content>: UIHostingController<Content> where Content: View {}

extension View {
	@ViewBuilder
    func conditionalModifier<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
         if conditional {
             content(self)
         } else {
             self
         }
     }

    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }

    func defaultShadows() -> some View {
        self.shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.1), radius: 2, x: 0, y: 0)
        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.05), radius: 12, x: 0, y: 0)
        .shadow(color: Color(red: 1, green: 1, blue: 1, opacity: 1), radius: 8, x: 0, y: 0)
    }

    func presentContent<ContentView>(isPresented: Binding<Bool>,
                                     tag: Int,
                                     animated: Bool = true,
                                     content: (Binding<Bool>) -> ContentView) -> some View where ContentView: View {
        let presentingController = UIApplication.shared.topMostController() as? PresentedHostingController<ContentView>
        if isPresented.wrappedValue {
            guard presentingController?.view.tag != tag else {
                // this prevent from presenting one more instance of controller
                // when SwiftUI View redraw body during presentation of this controller
                return self
            }

            if let controller = presentingController {
                controller.dismiss(animated: false)
            }

            let presentableContent = PresentedHostingController<ContentView>(
                rootView: content(isPresented)
            )
            presentableContent.modalPresentationStyle = .overCurrentContext
            presentableContent.modalTransitionStyle = .crossDissolve
            presentableContent.view.backgroundColor = .black.withAlphaComponent(0.4)
            presentableContent.view.tag = tag
            UIApplication.shared.topMostController()?.present(presentableContent, animated: animated)
        } else {
            if let controller = presentingController, tag == controller.view.tag {
                controller.dismiss(animated: true)
            }
        }

        return self
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, 
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

public struct StripesConfig {
    var background: Color
    var foreground: Color
    var degrees: Double
    var barWidth: CGFloat
    var barSpacing: CGFloat

    public init(background: Color = Color.pink.opacity(0.5), foreground: Color = Color.pink.opacity(0.8),
                degrees: Double = 30, barWidth: CGFloat = 20, barSpacing: CGFloat = 20) {
        self.background = background
        self.foreground = foreground
        self.degrees = degrees
        self.barWidth = barWidth
        self.barSpacing = barSpacing
    }

    public static let `default` = StripesConfig()
}

public struct Stripes: View {
    var config: StripesConfig

    public init(config: StripesConfig) {
        self.config = config
    }

    public var body: some View {
        GeometryReader { geometry in
            let longSide = max(geometry.size.width, geometry.size.height)
            let itemWidth = config.barWidth + config.barSpacing
            let items = Int(2 * longSide / itemWidth)
            HStack(spacing: config.barSpacing) {
                ForEach(0..<items, id: \.self) { _ in
                    config.foreground
                        .frame(width: config.barWidth, height: 2 * longSide)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .rotationEffect(Angle(degrees: config.degrees), anchor: .center)
            .offset(x: -longSide / 2, y: -longSide / 2)
            .background(config.background)
        }
        .clipped()
    }
}

public struct Squares: View {
    var configA: StripesConfig
    var configB: StripesConfig

    public init(config: StripesConfig) {
        configA = config
        configB = config
        configB.degrees = config.degrees - 90
    }

    public var body: some View {
        ZStack {
            Stripes(config: configA)
            Stripes(config: configB)
        }
    }
}

struct Stripes_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Stripes(config: .default).frame(width: 200, height: 200)

            Squares(config: .default).frame(width: 200, height: 200)

            ZStack {
                Stripes(config: StripesConfig(background: Color.blue.opacity(0.2),
                                              foreground: Color.blue.opacity(0.4), degrees: 45))
                Stripes(config: StripesConfig(background: Color.blue.opacity(0.1),
                                              foreground: Color.blue.opacity(0.3), degrees: -45))
            }
            .frame(width: 414, height: 896, alignment: .center)
            .background(Color.black)

            ZStack {
                Stripes(config: StripesConfig(background: Color.red.opacity(0.2),
                                              foreground: Color.blue.opacity(0.6),
                                              degrees: 45, barWidth: 50, barSpacing: 20))
                Stripes(config: StripesConfig(background: Color.red.opacity(0.2),
                                              foreground: Color.white.opacity(0.15),
                                              degrees: -45, barWidth: 50, barSpacing: 20))
            }
            .frame(width: 896, height: 414, alignment: .center)
            .background(Color.black)

            ZStack {
                Stripes(config: StripesConfig(background: Color.clear,
                                              foreground: Color.blue.opacity(0.2), degrees: 56))
            }
            .frame(width: 896, height: 414, alignment: .center)
            .background(Color.white)

            ZStack {
                Stripes(config: StripesConfig(background: Color.green.opacity(0.6),
                                              foreground: Color.white.opacity(0.3), degrees: 0,
                                              barWidth: 50, barSpacing: 50))
            }
            .frame(width: 896, height: 414, alignment: .center)
            .background(Color.black)
        }
    }
}
