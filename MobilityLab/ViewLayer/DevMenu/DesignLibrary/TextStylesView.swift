//
//  TextStylesView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct TextStylesView: View {
    var body: some View {
        Form {
            Section(header: Text("Headers - Avenir Black").textStyle(.subtitle)) {
                Text("Header 1 - 40pt")
                    .textStyle(.header1)
                
                Text("Header 2 - 32pt")
                    .textStyle(.header2)
                
                Text("Header 3 Avenir Heavy 24pt")
                    .textStyle(.header3)
                
                Text("Header 4 - Avenir Black 22pt")
                    .textStyle(.header4)
                
                Text("Header 5 - Avenir Black 20pt")
                    .textStyle(.header5)
                
                Text("Header 6 - Avenir Black 18pt")
                    .textStyle(.header6)
            }
            
            Section(header: Text("Body & Btn").textStyle(.subtitle)) {
                Text("Button – Avenir Heavy 16pt")
                    .textStyle(.bold)

                Text("Body – Avenir Roman 16pt")
                    .textStyle(.body)

                Text("Body 1 – Avenir Heavy 16pt")
                    .textStyle(.body1)
                
                Text("Body 2 - Avenir Book 16pt")
                    .textStyle(.body2)
            }
            
            Section(header: Text("Other").textStyle(.subtitle)) {
                Text("Subtitle - Avenir Roman 14pt")
                    .textStyle(.subtitle)
                
                Text("Caption – Avenir Roman 12pt")
                    .textStyle(.caption)
                
                Text("Overline – Avener Roman 10pt")
                    .textStyle(.overline)
            }
        }
        .navigationBarTitle("Text Styles")
    }
}

struct TextStylesView_Previews: PreviewProvider {
    static var previews: some View {
        TextStylesView()
    }
}
