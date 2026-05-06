//
//  DestructiveAlertCard.swift
//  SensorSuite BMM
//
//  Created by Vadym Riznychok on 6/27/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//
import SwiftUI

struct DestructiveAlertCard: View {
    private let title: String
    private let msg: String
    private let primaryString: String
    private let primaryAction: () -> Void
    private let destructiveString: String
    private let destructiveAction: () -> Void
	private let textAlignment: TextAlignment

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack(alignment: .center, content: {
                    Spacer()
                    Text(title)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal1)
                    Spacer()
                })
                Spacer()
                    .frame(height: 6)
                Text(msg)
                    .frame(maxWidth: .infinity, alignment: .leading)
					.multilineTextAlignment(textAlignment)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            Divider()
            HStack(alignment: .center) {
                Button {
                    primaryAction()
                } label: {
                    Text(primaryString)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.indigo1)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                Divider()
                    .frame(height: 24)
                Button {
                    destructiveAction()
                } label: {
                    Text(destructiveString)
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.red2Updated)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
            }
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 1)
        )
    }

    // MARK: - Init
	init(
		title: String,
		msg: String,
		primaryString: String,
		primaryAction: @escaping () -> Void,
		destructiveString: String,
		destructiveAction: @escaping () -> Void,
		textAlignemnt: TextAlignment = .leading
	) {
		self.title = title
		self.msg = msg
		self.primaryString = primaryString
		self.primaryAction = primaryAction
		self.destructiveString = destructiveString
		self.destructiveAction = destructiveAction
		self.textAlignment = textAlignemnt
    }
}

// MARK: - Preview
struct DestructiveAlertCard_Previews: PreviewProvider {
    static var previews: some View {
        DestructiveAlertCard(title: "Test", msg: "test message",
                             primaryString: "Cancel",
                             primaryAction: { },
                             destructiveString: "Delete") {
        }
    }
}
