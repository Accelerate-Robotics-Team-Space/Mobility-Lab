//
//  DesignLibView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct DesignLibView: View {
    var body: some View {
        Form {
            Section(header: Text("Design").textStyle(.subtitle)) {
                NavigationLink("Color Palette", destination: ColorPaletteView())
                    .menuCellStyle()
                
                NavigationLink("Text Styles", destination: TextStylesView())
                    .menuCellStyle()
            }
            
            Section(header: Text("Components").textStyle(.subtitle)) {
                NavigationLink("Button Styles", destination: BtnStylesView())
                    .menuCellStyle()
                
                NavigationLink("Button Interactions", destination: BtnInteractionView())
                    .menuCellStyle()
                
                NavigationLink("Radio Button Styles", destination: RadioBtnStylesView())
                    .menuCellStyle()
                
//                NavigationLink("Input Field", destination: InputFieldExampleView())
//                    .menuCellStyle()
                
                NavigationLink("PopUp Alert", destination: PopupAlertExampleView())
                    .menuCellStyle()
                
                NavigationLink("Bottom Sheet",
                               destination: BottomSheetExampleView())
                    .menuCellStyle()
            }
        }
        .navigationBarTitle("Design Library")
    }
}

struct DesignLibView_Previews: PreviewProvider {
    static var previews: some View {
        DesignLibView()
    }
}
