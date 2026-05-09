//
//  DetailedRadioBtn.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/6/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

enum RadioBtnStyle {
    case simple(title: String)
    case simpleImage(title: String, image: String)
    case detailed(title: String, body: String)
    case detailedImage(title: String, body: String, image: String)
    
    var title: String {
        switch self {
        case .simple(let title):
            return title
        case .simpleImage(let title, _):
            return title
        case .detailed(let title, _):
            return title
        case .detailedImage(let title, _, _):
            return title
        }
    }
    
    var imageStr: String? {
        switch self {
        case .simpleImage(_, let image):
            return image
        case .detailedImage(_, _, let image):
            return image
        default:
            return nil
        }
    }
    
    var bodyStr: String? {
        switch self {
        case .detailed(_, let body):
            return body
        case .detailedImage(_, let body, _):
            return body
        default:
            return nil
        }
    }
}

struct DetailedRadioBtn: View {
    @State private(set) var isSelected = false
    
    private var btnStyle: RadioBtnStyle
    private var btnAction: (Bool) -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            isSelected.toggle()
            btnAction(isSelected)
        }, label: {
            HStack {
                Image(isSelected ? R.image.checkboxFilled.name : R.image.checkboxEmpty.name)
                    .renderingMode(.template)
                    .foregroundColor(isSelected ? .white : .aqua)
                    .padding(.horizontal, 16)
                
                VStack(alignment: .leading) {
                    Text(btnStyle.title)
                        .textStyle(.header4, color: isSelected ? .white : .aqua)

                    if let bodyStr = btnStyle.bodyStr {
                        Text(bodyStr)
                            .textStyle(.subtitle, color: isSelected ? .white : .aqua)
                    }
                }
                
                Spacer()
                
                if let imageStr = btnStyle.imageStr {
                    Image(imageStr)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80)
            .conditionalModifier(!isSelected) {
                $0.overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.aqua, lineWidth: 2)
                )
            }
            .conditionalModifier(isSelected) {
                $0.background(Color.aqua)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .padding(.horizontal)
        })
    }
    
    // MARK: - Init
    init(_ someStyle: RadioBtnStyle, onToggle: @escaping (Bool) -> Void) {
        btnStyle = someStyle
        btnAction = onToggle
    }
}

struct DetailedRadioBtn_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DetailedRadioBtn(.simple(title: "Simple")) { _ in
                // Do stuff
            }
            DetailedRadioBtn(.simpleImage(title: "Simple image", image: R.image.positionSupine1.name)) { _ in
                // Do stuff
            }
            DetailedRadioBtn(.detailed(title: "Detailed", body: "With body")) { _ in
                // Do stuff
            }
            DetailedRadioBtn(.detailedImage(title: "Detailed image", body: "With body", image: R.image.positionSupine1.name)) { _ in
                // Do stuff
            }
        }
    }
}
