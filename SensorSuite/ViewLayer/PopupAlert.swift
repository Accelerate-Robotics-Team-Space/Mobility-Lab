//
//  PopUpAlert.swift
//  SensorSuite
//
//  Created by Josh Franco on 11/12/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct PopupAlert: View {
    private let popupCta: CtaType
    private let popupExit: ExitType
    
    private let imageName: String?
    private let popUpTitle: String
    private let popUpMsg: String
    private let contraindications: Bool
    
    @State private var hasPaceMaker = false
    @Binding private var hasBrokenSkin: Bool
    @State private var displayWarning = false
    
    struct PopupBtn {
        let labelStr: String
        let cta: () -> Void
    }
    
    enum CtaType {
        case `default`(primaryBtn: PopupBtn, secondaryBtn: PopupBtn)
        case destructive(primaryBtn: PopupBtn, secondaryBtn: PopupBtn)
        case noCta
        
        var primaryLabelStr: String {
            switch self {
            case .default(let primaryBtn, _):
                return primaryBtn.labelStr
            case .destructive(let primaryBtn, _):
                return primaryBtn.labelStr
            case .noCta: return "?"
            }
        }
        
        var secondaryLabelStr: String {
            switch self {
            case .default(_, let secondaryBtn):
                return secondaryBtn.labelStr
            case .destructive(_, let secondaryBtn):
                return secondaryBtn.labelStr
            case .noCta: return "?"
            }
        }
        
        var showBtns: Bool {
            switch self {
            case .default, .destructive:
                return true
            case .noCta:
                return false
            }
        }
        
        var isDestructive: Bool {
            switch self {
            case .destructive:
                return true
            default: return false
            }
        }
        
        var primaryCta: () -> Void {
            switch self {
            case .default(let primaryBtn, _), .destructive(let primaryBtn, _):
                return primaryBtn.cta
            case .noCta:
                return {}
            }
        }
        
        var secondaryCta: () -> Void {
            switch self {
            case .default(_, let secondaryCta), .destructive(_, let secondaryCta):
                return secondaryCta.cta
            case .noCta:
                return {}
            }
        }
    }
    
    enum ExitType {
        case none
        case `default`(cta: () -> Void)
        
        var showBtn: Bool {
            switch self {
            case .default: return true
            case .none: return false
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 24) {
            if let imageName = imageName {
                Image(imageName)
                    .resizable()
                    .frame(width: 200, height: 200)
            }
            
            VStack(spacing: contraindications ? 0 : 8) {
                Text(popUpTitle)
                    .textStyle(.header4)
                    .padding(.horizontal, 8)
                
                Text(popUpMsg)
                    .textStyle(.body2)
                    .padding(.horizontal, 8)
                    .multilineTextAlignment(.leading)
                
                if contraindications {
                    ZStack {
                        VStack {
                            if !displayWarning {
                                HStack {
                                    Text("Does the patient have a pacemaker?")
                                    Picker(selection: $hasPaceMaker, label: Text("")) {
                                        Text("Yes")
                                            .tag(true)
                                        Text("No")
                                            .tag(false)
                                    }.pickerStyle(.segmented)
                                }
                                .padding()
                                HStack {
                                    Text("Does the patient have any broken skin on their sternum?")
                                    Picker(selection: $hasBrokenSkin, label: Text("")) {
                                        Text("Yes")
                                            .tag(true)
                                        Text("No")
                                            .tag(false)
                                    }.pickerStyle(.segmented)
                                }
                                .padding()
                            } else {
                                VStack {
                                    Text(hasPaceMaker ?
                                         "Patient monitoring is not recommended with patients with pacemakers" :
                                            "Caregivers please review the skin before placing the sensor")
                                    .font(.custom("Avenir-Heavy", size: 18))
                                }
                                .padding()
                            }
                        }
                        .interactiveDismissDisabled()
                        .frame(height: displayWarning ? 90 : 180)
                    }
                }
                
                if popupCta.showBtns && !displayWarning {
                    VStack(spacing: 9) {
                        Button(action: {
                            handlePopupCta(isPrimary: true)
                        }, label: {
                            Text(popupCta.primaryLabelStr)
                                .frame(maxWidth: .infinity)
                        })
                        .buttonStyle(primaryButtonStyle())
                        .padding(.horizontal)
                        
                        Button(action: {
                            handlePopupCta(isPrimary: false)
                        }, label: {
                            Text(popupCta.secondaryLabelStr)
                                .frame(maxWidth: .infinity)
                        })
                        .buttonStyle(secondaryButtonStyle())
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white)
                .shadow(color: .gray, radius: 12, x: 0, y: 5)
        )
        .padding()
        .conditionalModifier(popupExit.showBtn && !displayWarning) {
            $0.overlay(
                VStack {
                    HStack {
                        Spacer()
                        ALTExitButton {
                            handleExitCta()
                        }
                        .offset(x: -31.0, y: 31.0)
                        .frame(width: 19, height: 19)
                    }
                    Spacer()
                }
            )
            .transition(
                .asymmetric(insertion: AnyTransition.opacity
                    .combined(with: .slide)
                    .animation(.interactiveSpring()),
                            removal: AnyTransition.opacity
                    .combined(with: .slide)
                    .animation(.interactiveSpring()))
            )
        }
        .onChange(of: displayWarning) { _ in
            if contraindications && displayWarning && hasPaceMaker {
                Timer.scheduledTimer(withTimeInterval: 7, repeats: false) { _ in
                    withAnimation {
                        popupCta.secondaryCta()
                    }
                }
            }
            if contraindications && displayWarning && hasBrokenSkin {
                Timer.scheduledTimer(withTimeInterval: 7, repeats: false) { _ in
                    withAnimation {
                        popupCta.primaryCta()
                    }
                }
            }
        }
    }
    
    // MARK: - Init
    init(title: String, msg: String, image: String?, popupBtns: CtaType, popupExit: ExitType,
         contraindications: Bool = false, hasBrokenSkin: Binding<Bool> = .constant(false)) {
        self.popUpTitle = title
        self.popUpMsg = msg
        self.imageName = image
        self.popupCta = popupBtns
        self.popupExit = popupExit
        self.contraindications = contraindications
        self._hasBrokenSkin = hasBrokenSkin
    }

    private func primaryButtonStyle() -> some ButtonStyle {
        if displayWarning {
            return ALTButtonStyle().backgroundAndBorderColor(.indigo5).textColor(.indigo1)
        } else {
            if popupCta.isDestructive {
                return ALTButtonStyle().backgroundAndBorderColor(.vermillion).textColor(.white)
            } else {
                return ALTButtonStyle()
            }
        }
    }

    private func secondaryButtonStyle() -> some ButtonStyle {
        if displayWarning {
            return ALTButtonStyle().backgroundAndBorderColor(.indigo5).textColor(.indigo2)
        } else {
            if popupCta.isDestructive {
                return ALTButtonStyle().backgroundAndBorderColor(.charcoal.opacity(0.2)).textColor(.charcoal)
            } else {
                return ALTButtonStyle().backgroundAndBorderColor(.indigo5).textColor(.indigo2)
            }
        }
    }
}

struct TextView: View {
    @Binding var paceMakerWarning: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Text(paceMakerWarning ?
                 "Patient monitoring is not recommended with patients with pacemakers" :
                    "Caregivers please review the skin before placing the sensor")
            .font(.custom("Avenir-Heavy", size: 18))
        }
        .padding()
    }
}

// MARK: - Private
private extension PopupAlert {
    func handlePopupCta(isPrimary: Bool) {
        switch popupCta {
        case .default(let primaryBtn, let secondaryBtn):
            if isPrimary && contraindications {
                if (hasPaceMaker || hasBrokenSkin) && displayWarning == false {
                    withAnimation {
                        displayWarning = true
                    }
                } else if (!hasPaceMaker && !hasBrokenSkin && displayWarning == false) || (displayWarning && hasBrokenSkin) {
                    primaryBtn.cta()
                } else {
                    secondaryBtn.cta()
                }
            } else if isPrimary {
                primaryBtn.cta()
            } else {
                secondaryBtn.cta()
            }
        case .destructive(let primaryBtn, let secondaryBtn):
            if isPrimary {
                primaryBtn.cta()
            } else {
                secondaryBtn.cta()
            }
        case .noCta: break
        }
    }
    
    func handleExitCta() {
        switch popupExit {
        case .default(let cta):
            cta()
        case .none: break
        }
    }
}

// MARK: - Preview
struct PopUpAlert_Previews: PreviewProvider {
    // swiftlint:disable:next line_length
    private static let loremIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Enim urna ultricies dis sagittis. In nibh tortor, diam posuere pellentesque ac suspendisse ac."
   
    static var previews: some View {
        PopupAlert(title: "Some Title",
                   msg: loremIpsum,
                   image: R.image.placeholder.name,
                   popupBtns: .default(primaryBtn: .init(labelStr: "Primary Cta", cta: {}),
                                       secondaryBtn: .init(labelStr: "Secondary Cta", cta: {})),
                   popupExit: .default(cta: {}))
    }
}
