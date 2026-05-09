//
//  ALTExitButton.swift
//  MobilityLab
//
//  Created by Vadym Riznychok on 5/11/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ALTExitButton: View {
    private var btnAction: () -> Void

    // MARK: - Body
    var body: some View {
        Button(action: btnAction, label: {
            R.image.closeButton.image
                .renderingMode(.template)
                .tint(.charcoal3)
        })
    }

    // MARK: - Init
    init(action: @escaping () -> Void) {
        btnAction = action
    }
}

// MARK: - Preview
struct ALTExitButton_Previews: PreviewProvider {
    static var previews: some View {
        ALTExitButton {
            // Do stuff
        }
    }
}
