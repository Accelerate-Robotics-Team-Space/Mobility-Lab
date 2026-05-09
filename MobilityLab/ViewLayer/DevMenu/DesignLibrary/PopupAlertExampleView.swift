//
//  PopupAlertExampleView.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/12/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PopupAlertExampleView: View {
    @State private var showPopup = false
    
    var body: some View {
        ZStack {
            Button(action: {
                showPopup.toggle()
            }, label: {
                Text("Toggle PopUp!")
            })
            .flatBtnStyle()
            
            VStack {
                if showPopup {
                    PopupAlert(title: "Some Title",
                               msg: "Some long msg that will inform the user of something",
                               image: R.image.placeholder.name,
                               popupBtns: .default(primaryBtn: .init(labelStr: "Ok", cta: { showPopup.toggle() }),
                                                   secondaryBtn: .init(labelStr: "No!", cta: { showPopup.toggle() })),
                               popupExit: .default(cta: { showPopup.toggle() }))
                }
            }
        }
    }
}

struct PopupAlertExampleView_Previews: PreviewProvider {
    static var previews: some View {
        PopupAlertExampleView()
    }
}
