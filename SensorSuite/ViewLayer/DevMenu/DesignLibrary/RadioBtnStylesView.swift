//
//  RadioBtnStyles.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/10/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct RadioBtnStylesView: View {
    private var loremIpsum = """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
    """
    
    var body: some View {
        Form {
            DetailedRadioBtn(.simple(title: "Some Title")) { _ in }
            
            DetailedRadioBtn(.simpleImage(title: "Some Title",
                                          image: R.image.placeholder.name)) { _ in }
            
            DetailedRadioBtn(.detailed(title: "Some Title", body: loremIpsum)) { _ in }
            
            DetailedRadioBtn(.detailedImage(title: "Some Title",
                                            body: loremIpsum,
                                            image: R.image.placeholder.name)) { _ in }
        }
        .navigationBarTitle("Radio Buttons")
    }
}

struct RadioBtnStyles_Previews: PreviewProvider {
    static var previews: some View {
        RadioBtnStylesView()
    }
}
