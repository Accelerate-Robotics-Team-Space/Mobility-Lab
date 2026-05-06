//
//  AlertCardView.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 12/5/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//
import SwiftUI

struct AlertCardView: View {
    private let title: String
    private let msg: String
    private let secondaryButtonString: String
    private let secondaryButtonAction: () -> Void
    private let primaryButtonString: String
    private let primaryButtonAction: () -> Void

    var body: some View {
        VStack {
            VStack {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.charcoal1)
                Text(msg)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            Divider()
            HStack {
                Button {
                    secondaryButtonAction()
                } label: {
                    Text(secondaryButtonString)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.indigo1)
                }
                .frame(maxWidth: .infinity)
                Divider()
                    .frame(height: 16)
                Button {
                    primaryButtonAction()
                } label: {
                    Text(primaryButtonString)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.indigo1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 1)
        )
    }

    // MARK: - Init
    init(title: String,
         msg: String,
         secondaryButtonString: String,
         secondaryButtonAction: @escaping () -> Void,
         primaryButtonString: String,
         primaryButtonAction: @escaping () -> Void) {
        self.title = title
        self.msg = msg
        self.secondaryButtonString = secondaryButtonString
        self.secondaryButtonAction = secondaryButtonAction
        self.primaryButtonString = primaryButtonString
        self.primaryButtonAction = primaryButtonAction
    }
}
