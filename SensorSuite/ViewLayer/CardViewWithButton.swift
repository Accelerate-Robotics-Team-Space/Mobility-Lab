//
//  CardViewWithButton.swift
//  SensorSuite
//
// Created by Nguyen Bui on 11/23/21.
// Copyright (c) 2021 Atlas LiftTech. All rights reserved.
//

import AVFoundation
import SwiftUI

struct CardViewWithButton: View {
    private let title: String
    private let msg: String
    private let buttonTitle: String
    private let buttonAction: () -> Void
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    Image(R.image.redWarning.name)
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                }
                Text(msg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            Divider()
            VStack {
                Button {
                    buttonAction()
                } label: {
                    Text(buttonTitle)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.indigo1)
                }
            }
            .padding(.horizontal, 16)
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
    init(title: String, msg: String, buttonTitle: String, buttonAction: @escaping () -> Void) {
        self.title = title
        self.msg = msg
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
}
struct CardViewWith2Buttons: View {
    private let title: String
    private let msg: String
    private let secondaryButtonString: String
    private let secondaryButtonAction: () -> Void
    private let primaryButtonString: String
    private let primaryButtonAction: () -> Void
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    Image(R.image.redWarning.name)
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                }
                Text(msg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            Divider()
            VStack(alignment: .center, spacing: 0) {
                Button {
                    secondaryButtonAction()
                } label: {
                    Text(secondaryButtonString)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.indigo1)
                }
                Divider()
                    .frame(height: 16)
                Button {
                    primaryButtonAction()
                } label: {
                    Text(primaryButtonString)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.indigo1)
                }
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
struct SimpleCardView: View {
    private let title: String
    private let msg: String
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    Image(R.image.redWarning.name)
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                }
                Text(msg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 1)
        )
    }
    
    // MARK: - Init
    init(title: String, msg: String) {
        self.title = title
        self.msg = msg
    }
}

// MARK: - Preview
struct CardViewWithButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CardViewWithButton(title: R.string.localizable.wrongPositionDetected(),
                               msg: R.string.localizable.wearableDetectedWrongPositionOver(),
                               buttonTitle: R.string.localizable.dismiss(),
                               buttonAction: {})
            CardViewWithButton(title: R.string.localizable.timeToTurnYourPatient(),
                               msg: R.string.localizable.itThatTimeToTurn(R.string.localizable.leftLateral()),
                               buttonTitle: R.string.localizable.dismiss(),
                               buttonAction: {})
            CardViewWithButton(title: "Low Battery",
                               msg: "The sensor is low on battery. Please swap and charge.",
                               buttonTitle: R.string.localizable.dismiss(),
                               buttonAction: {})
            SimpleCardView(title: "Sensor Disconnect",
                           msg: "No sensor detected. Pausing the session now.")
            CardViewWith2Buttons(title: "Your patch has expired",
                                 msg: "It's that time again. Please change the patch on your patient",
                                 secondaryButtonString: "Continue Without Changing",
                                 secondaryButtonAction: { logger.info("You clicked secondary") },
                                 primaryButtonString: "Swap Patch",
                                 primaryButtonAction: { logger.info("You clicked primary") })
        }
    }
}
