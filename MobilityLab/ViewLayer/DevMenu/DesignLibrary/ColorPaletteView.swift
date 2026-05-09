//
//  ColorPaletteView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

private struct ColorPaletteCell: View {
    private let cornerRad: CGFloat = 10
    private let strokeLineWidth: CGFloat = 2
    private let frameSize: CGFloat = 100
    
    private var title: String
    private var color: Color
    private var outlineColor: Color
    
    var body: some View {
        HStack {
            Text(title)
                .textStyle(.body1)
            
            Spacer()
            
            RoundedRectangle(cornerRadius: cornerRad)
                .frame(width: frameSize, height: frameSize)
                .foregroundColor(color)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRad)
                        .stroke(outlineColor, lineWidth: strokeLineWidth)
                )
        }
    }
    
    init(_ title: String, color: Color, outlineColor: Color = .black) {
        self.title = title
        self.color = color
        self.outlineColor = outlineColor
    }
}

struct ColorPaletteView: View {
    private let cornerRad: CGFloat = 10
    private let strokeLineWidth: CGFloat = 2
    private let frameSize: CGFloat = 100
    
    var body: some View {
        Form {
            Section(header: Text("Primary Colors").textStyle(.subtitle)) {
                ColorPaletteCell("Aqua", color: .aqua)
                ColorPaletteCell("Charcoal", color: .charcoal)
                ColorPaletteCell("Cornflower", color: .cornflower)
                ColorPaletteCell("ColumbiaBlue", color: .columbiaBlue)
            }
            
            Section(header: Text("Accent Colors").textStyle(.subtitle)) {
                ColorPaletteCell("Grass", color: .grass)
                ColorPaletteCell("Honey", color: .honey)
                ColorPaletteCell("Tangerine", color: .tangerine)
                ColorPaletteCell("Vermillion", color: .vermillion)
                ColorPaletteCell("Violet", color: .violet)
            }
            
            Section(header: Text("Greys").textStyle(.subtitle)) {
                ColorPaletteCell("Ash", color: .ash)
                ColorPaletteCell("Silver", color: .silver)
                ColorPaletteCell("Steel", color: .steel)
            }
        }
        .navigationBarTitle("Color Palette")
    }
}

struct ColorPaletteView_Previews: PreviewProvider {
    static var previews: some View {
        ColorPaletteView()
    }
}
