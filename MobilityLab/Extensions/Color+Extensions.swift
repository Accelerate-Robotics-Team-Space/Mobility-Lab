//
//  Color+Extensions.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/5/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

extension Color {
    static var aqua: Color {
        R.color.aqua.color
    }
    
    static var aqua1: Color {
        R.color.aqua1.color
    }
    
    static var aqua4: Color {
        R.color.aqua4.color
    }
    
    static var aqua5: Color {
        R.color.aqua5.color
    }

    static var indigo1: Color {
        R.color.indigo1.color
    }

    static var indigo2: Color {
        R.color.indigo2.color
    }

    static var indigo5: Color {
        R.color.indigo5.color
    }

    static var indigoBkgd: Color {
        R.color.indigoBkgd.color
    }

    static var purple2: Color {
        R.color.purple2.color
    }
    
    static var ash: Color {
        R.color.ash.color
    }
    
    static var charcoal: Color {
        R.color.charcoal.color
    }
    
    static var charcoal1: Color {
        R.color.charcoal1.color
    }
    
    static var charcoal3: Color {
        R.color.charcoal3.color
    }
    
    static var charcoal4: Color {
        R.color.charcoal4.color
    }
    
    static var charcoal5: Color {
        R.color.charcoal5.color
    }
    
    static var columbiaBlue: Color {
        R.color.columbiaBlue.color
    }
    
    static var cornflower: Color {
        R.color.cornflower.color
    }
    
    static var cloud: Color {
        R.color.cloud.color
    }
    
    static var errigalWhite: Color {
        R.color.errigalWhite.color
    }
    
    static var faintingLight: Color {
        R.color.faintingLight.color
    }
    
    static var green1: Color {
        R.color.green1.color
    }
    
    static var green2: Color {
        R.color.green2.color
    }
    
    static var green3: Color {
        R.color.green3.color
    }
    
    static var green5: Color {
        R.color.green5.color
    }
    
    static var grass: Color {
        R.color.grass.color
    }
    
    static var honey: Color {
        R.color.honey.color
    }
    
    static var lightAqua: Color {
        R.color.lightAqua.color
    }
    
    static var oregonBlue: Color {
        R.color.oregonBlue.color
    }
    
    static var red1: Color {
        R.color.red1.color
    }
    
    static var red2: Color {
        R.color.red2.color
    }

    static var red2Updated: Color {
        R.color.red2Updated.color
    }
    
    static var red3: Color {
        R.color.red3.color
    }
    
    static var red4: Color {
        R.color.red4.color
    }
    
    static var red5: Color {
        R.color.red5.color
    }
    
    static var silver: Color {
        R.color.silver.color
    }
    
    static var steel: Color {
        R.color.steel.color
    }
    
    static var tangerine: Color {
        R.color.tangerine.color
    }
    
    static var vermillion: Color {
        R.color.vermillion.color
    }
    
    static var violet: Color {
        R.color.violet.color
    }
    
    static var yellow1: Color {
        R.color.yellow1.color
    }
    
    init(rRed: Int, gGreen: Int, bBlue: Int, opacity: CGFloat = 1.0) {
        self.init(red: CGFloat(rRed) / 255.0, green: CGFloat(gGreen) / 255.0, blue: CGFloat(bBlue) / 255.0, opacity: opacity)
    }
    
    init(hex: Int, opacity: CGFloat = 1.0) {
        self.init(
            rRed: (hex >> 16) & 0xFF,
            gGreen: (hex >> 8) & 0xFF,
            bBlue: hex & 0xFF,
            opacity: opacity
        )
    }
}
