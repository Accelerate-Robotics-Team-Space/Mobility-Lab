//
//  BindedRadioBtn.swift
//  MobilityLab
//
//  Created by Josh Franco on 11/30/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct BindedRadioBtn: View {
    @Binding var isSelected: Bool?
    
    private var btnStyle: RadioBtnStyle
    private var btnAction: (Bool) -> Void
    
    private var isBtnSelected: Bool {
        isSelected ?? false
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            isSelected?.toggle()
            btnAction(isBtnSelected)
        }, label: {
            HStack {
                if let imageStr = btnStyle.imageStr {
                    Image(imageStr)
                        .resizable()
                        .frame(width: 48, height: 12.87)
                        .padding()
                }
                
                VStack(alignment: .leading) {
                    Text(btnStyle.title)
                        .textStyle(.bold, color: .charcoal1)
                    
                    if let bodyStr = btnStyle.bodyStr {
                        Text(bodyStr)
                            .font(.custom("Avenir", size: 16))
                            .foregroundColor(.charcoal)
                    }
                }
                
                Spacer()
                
                Image(isBtnSelected ? R.image.radioTicked.name : R.image.radioUnticked.name)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(isBtnSelected ? .black : .charcoal5)
                    .frame(width: 20, height: 20)
                    .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56)
            .conditionalModifier(isBtnSelected) {
                $0.background(Color.indigo5)
            }
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
        
        if btnStyle.imageStr != "position-right-lateral-1" {
            Divider()
                .frame(height: 1)
                .background(Color(red: 0, green: 0, blue: 0, opacity: 0.1))
        }
    }
    
    // MARK: - Init
    init(_ someStyle: RadioBtnStyle, binding: Binding<Bool?>, onToggle: @escaping (Bool) -> Void) {
        self.btnStyle = someStyle
        self._isSelected = binding
        self.btnAction = onToggle
    }
}

struct BindedRadioBtn_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BindedRadioBtn(.simple(title: "Simple"), binding: .constant(false)) { _ in
                // Do stuff
            }
            BindedRadioBtn(.simpleImage(title: "Simple image", image: R.image.positionSupine1.name), binding: .constant(false)) { _ in
                // Do stuff
            }
            BindedRadioBtn(.detailed(title: "Detailed", body: "With body"), binding: .constant(false)) { _ in
                // Do stuff
            }
            BindedRadioBtn(.detailedImage(title: "Detailed image", body: "With body",
                                          image: R.image.positionSupine1.name), binding: .constant(false)) { _ in
                // Do stuff
            }
        }
    }
}
