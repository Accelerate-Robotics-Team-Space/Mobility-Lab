//
//  MaterialTextField.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/6/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

enum Requirement {
    case none
    case required
    case optional
    case inches
    case centimeters
    case pounds
    case kilograms
    case seconds
    case remainingSeconds
    
    var requirementStr: String {
        switch self {
        case .none:
            return ""
        case .required:
            return "(" + R.string.localizable.required() + ")"
        case .optional:
            return "(" + R.string.localizable.optional() + ")"
        case .inches:
            return R.string.localizable.inchesAbbr()
        case .centimeters:
            return "cm"
        case .pounds:
            return R.string.localizable.poundsAbbr()
        case .kilograms:
            return "kg"
        case .seconds:
            return "seconds"
        case .remainingSeconds:
            return "remaining seconds"
        }
    }
}

struct InputField: View {
    @Binding var inputText: String
    @Binding var textFieldRequirement: Requirement {
        didSet {
            if textFieldRequirement == .kilograms || textFieldRequirement == .centimeters ||
                textFieldRequirement == .pounds || textFieldRequirement == .inches {
                togglableRequirement = true
            } else {
                togglableRequirement = false
            }
        }
    }
    
    @State private(set) var titleStr: String
    @State private(set) var placeholderStr: String
    @State private(set) var maxCharCount: Int?
    @State private(set) var showError: Bool
    @State private(set) var errorMsg: String
    @State private(set) var onEditingAction: (Bool) -> Void
    @State private(set) var onCommitAction: () -> Void
    @State private var togglableRequirement: Bool = true
    @State private var requirementMenuShown: Bool = false
    @State private var charCounter: Int = 0

    private var atMaxCharConut: Bool {
        guard let maxCharCount = maxCharCount else { return false }
        return charCounter >= maxCharCount
    }

    // MARK: - Init
    init(_ title: String,
         placeholder: String,
         inputTxt: Binding<String>,
         requirement: Binding<Requirement> = .constant(.none),
         charCount: Int? = nil,
         errorState: Bool = false,
         errorMsg: String = "",
         onEditAction: @escaping (Bool) -> Void = { _ in },
         onCommitAction: @escaping () -> Void = {}) {
        self.titleStr = title
        self.placeholderStr = placeholder
        self._inputText = inputTxt
        self._textFieldRequirement = requirement
        self.maxCharCount = charCount
        self.showError = errorState
        self.errorMsg = errorMsg
        self.onEditingAction = onEditAction
        self.onCommitAction = onCommitAction
    }

    // MARK: - Body
    var body: some View {
        let textBinding = Binding<String>(
            get: { self.inputText },
            set: { self.handleBindingSetter($0) }
        )
        
        return ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    Text(titleStr)
                        .textStyle(.bold)
                    
                    Spacer()
                    
                    if textFieldRequirement != .none {
                        ZStack(alignment: .trailing) {
                            HStack(spacing: 0) {
                                requirementsText
                                if togglableRequirement {
                                    showMenuButton
                                }
                            }
                        }
                    }
                }
                
                textField(textBinding)

                if showError {
                    errorView
                }
            }
            if togglableRequirement {
                VStack(alignment: .trailing, spacing: 2) {
                    requirementShowButton
                    if requirementMenuShown {
                        requiredMeasurementStack
                    }
                }
            }
        }
    }
}

// MARK: - Private
private extension InputField {
    @ViewBuilder
    var requirementShowButton: some View {
        Button(action: {
            requirementMenuShown.toggle()
        }, label: {
            Image(R.image.chevronDown.name)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.black)
                .frame(width: 22, height: 22)
                .scaleEffect(CGSize(width: 1, height: requirementMenuShown ? 1 : -1))
        })
    }

    @ViewBuilder
    var requiredMeasurementStack: some View {
        VStack(alignment: .trailing) {
            VStack {
                if textFieldRequirement == .inches || textFieldRequirement == .centimeters {
                    lengthButton
                } else if textFieldRequirement == .pounds || textFieldRequirement == .kilograms {
                    massButton
                }
            }
        }
        .frame(width: 30)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray)
                .defaultShadows()
        )
        .offset(x: -15, y: -55)
    }

    @ViewBuilder
    var lengthButton: some View {
        Button {
            if textFieldRequirement == .inches {
                textFieldRequirement = .centimeters
            } else if textFieldRequirement == .centimeters {
                textFieldRequirement = .inches
            }
            requirementMenuShown = false
        } label: {
            if textFieldRequirement == .inches {
                Text(Requirement.centimeters.requirementStr)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.black)
            } else if textFieldRequirement == .centimeters {
                Text(Requirement.inches.requirementStr)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.black)
            }
        }
    }

    @ViewBuilder
    var massButton: some View {
        Button {
            if textFieldRequirement == .pounds {
                textFieldRequirement = .kilograms
            } else if textFieldRequirement == .kilograms {
                textFieldRequirement = .pounds
            }
            requirementMenuShown = false
        } label: {
            if textFieldRequirement == .pounds {
                Text(Requirement.kilograms.requirementStr)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.black)
            } else if textFieldRequirement == .kilograms {
                Text(Requirement.pounds.requirementStr)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(.black)
            }
        }
    }

    @ViewBuilder
    var requirementsText: some View {
        Text(textFieldRequirement.requirementStr)
            .bold()
            .font(.custom("Avenir-Heavy", size: 16))
            .foregroundColor(.charcoal3)
    }

    @ViewBuilder
    var showMenuButton: some View {
        VStack {
            Button(action: {
                requirementMenuShown.toggle()
            }, label: {
                Image(R.image.chevronDown.name)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.black)
                    .frame(width: 22, height: 22)
                    .scaleEffect(CGSize(width: 1, height: requirementMenuShown ? 1 : -1))
            })
        }
    }

    @ViewBuilder
    func textField(_ textBinding: Binding<String>) -> some View {
        TextField(placeholderStr,
                  text: textBinding,
                  onEditingChanged: updateCharCount,
                  onCommit: onTextCommit)
        .font(.custom("Avenir-Heavy", size: 16))
        .keyboardType(.numberPad)
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .defaultShadows()
        )
    }

    @ViewBuilder
    var errorView: some View {
        HStack {
            Circle()
                .frame(width: 16, height: 16)
                .foregroundColor(.vermillion)

            Text(errorMsg)
                .textStyle(.subtitle, color: .vermillion)

            Spacer()

            if maxCharCount != nil {
                if let maxCharCount = maxCharCount {
                    Text("\(charCounter)/\(maxCharCount)")
                        .textStyle(.subtitle)
                        .foregroundColor(atMaxCharConut ? .vermillion : .charcoal)
                }
            }
        }
    }

    func updateCharCount(_ changed: Bool) {
        onEditingAction(changed)
    }
    
    func onTextCommit() {
        onCommitAction()
    }
    
    func outlineColor() -> Color {
        if showError {
            return .vermillion
        } else if inputText.isEmpty {
            return .charcoal
        } else {
            return .aqua
        }
    }
    
    func handleBindingSetter(_ str: String) {
        let maxCount = maxCharCount ?? Int.max
        
        if str.count <= maxCount {
            inputText = str
            charCounter = str.count
        } else {
            inputText = String(str.prefix(maxCount))
        }
    }
}

// MARK: - Preview
struct MaterialTextField_Previews: PreviewProvider {
    @State private static var previewError = false
    @State private static var previewErrMsg = "Some Error Message"
    @State private static var previewInputText = ""
    
    static var previews: some View {
        VStack {
            InputField("Some Title", placeholder: "Some Placeholder",
                       inputTxt: $previewInputText, requirement: .constant(.pounds),
                       charCount: 5, errorState: true, errorMsg: "Some Error Msg")
            
            InputField("Some Title", placeholder: "Some Placeholder",
                       inputTxt: $previewInputText, requirement: .constant(.inches),
                       charCount: 5, errorState: true, errorMsg: "Some Error Msg")
        }
    }
}
