//
//  TriggerField.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/18/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct TriggerField: View {
    @Binding var selectedText: String?
    @Binding var isSelected: Bool
    
    @State private(set) var titleStr: String
    @State private(set) var placeholder: String
    @State private(set) var textFieldRequirement: Requirement
    @State private(set) var tapAction: () -> Void
    @State private(set) var showError: Bool
    @State private(set) var errorMsg: String
    
    enum Requirement {
        case none
        case required
        case optional
        
        var requirementStr: String {
            switch self {
            case .none:
                return ""
            case .required:
                return "(" + R.string.localizable.required() + ")"
            case .optional:
                return "(" + R.string.localizable.optional() + ")"
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack {
                Text(titleStr)
                    .textStyle(.bold)
                
                Spacer()
                
                if textFieldRequirement != .none {
                    Text(textFieldRequirement.requirementStr)
                        .bold()
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.charcoal3)
                }
            }
            
            Button(action: {
                tapAction()
            }, label: {
                HStack {
                    Text(selectedText == nil ? placeholder : selectedText ?? "?")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .bold()
                        .foregroundColor(selectedText == nil ? .charcoal4 : .charcoal1)
                    Spacer()
                    Image(R.image.arrowDown.name)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.charcoal)
                        .frame(width: 24, height: 24)
                }
            })
            .padding(.all, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .defaultShadows()
            )
            
            if showError {
                HStack {
                    Circle()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.vermillion)
                    
                    Text(errorMsg)
                        .textStyle(.subtitle, color: .vermillion)
                    
                    Spacer()
                }
            }
        }
    }

    // MARK: - Init
    init(_ titleStr: String, placeholder: String,
         selectedText: Binding<String?>,
         isSelected: Binding<Bool> = .constant(false),
         requirement: Requirement = .none,
         errorState: Bool = false, errorMsg: String = "?",
         tapAction: @escaping () -> Void) {
        self.titleStr = titleStr
        self.placeholder = placeholder
        self.textFieldRequirement = requirement
        
        self._selectedText = selectedText
        self._isSelected = isSelected
        self.tapAction = tapAction
        
        self.showError = errorState
        self.errorMsg = errorMsg
    }
}

// MARK: - Private
private extension TriggerField {
    func outlineColor() -> Color {
        if showError {
            return .vermillion
        } else if isSelected {
            return .aqua
        } else {
            return .charcoal
        }
    }
}

// MARK: - Preview
struct TriggerField_Previews: PreviewProvider {
    static var previews: some View {
        TriggerField("Some Title",
                     placeholder: "Select an option",
                     selectedText: .constant(nil),
                     errorState: false, errorMsg: "some error") {
            // do stuff
        }
    }
}
