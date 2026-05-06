//
//  PickerField.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI
import UIKit

class PickerTextField: UITextField {
    // MARK: - Public properties
    var alphaItems: [String]
    var betaItems: [String]
    
    @Binding var alphaIndex: Int?
    @Binding var betaIndex: Int?

    // MARK: - Initializers
    init(alphaItems: [String], betaItems: [String], alphaIndex: Binding<Int?>, betaIndex: Binding<Int?>) {
        self.alphaItems = alphaItems
        self.betaItems = betaItems
        
        self._alphaIndex = alphaIndex
        self._betaIndex = betaIndex
        
        super.init(frame: .zero)

        /// Adding this toolbar will cause a '[LayoutConstraints] Unable to simultaneously satisfy constraints.' in the debugger
        /// Seems to be a swiftUI issue, will take a deeper look if this problem effects usability
        let toolBar = UIToolbar()
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: .done,
                                         target: self,
                                         action: #selector(UITextField.doneButtonTapped(button:)))
        doneButton.tintColor = R.color.aqua()
        toolBar.items = [space, doneButton]
        toolBar.sizeToFit()
        toolBar.barTintColor = .white
        pickerView.backgroundColor = .white
        
        self.inputAccessoryView = toolBar
        self.inputView = pickerView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private properties
    private lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()

    // MARK: - Private methods
    @objc
    private func donePressed() {
        self.alphaIndex = self.pickerView.selectedRow(inComponent: 0)
        self.betaIndex = self.pickerView.selectedRow(inComponent: 1)
        
        self.endEditing(true)
    }
    
    // MARK: - Overrides
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate extension
extension PickerTextField: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if betaItems.isEmpty {
            return 1
        } else {
            return 2
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        (component == 1) ? betaItems.count : alphaItems.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        (component == 1) ? betaItems[row] : alphaItems[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 1 {
            self.betaIndex = row
        } else {
            self.alphaIndex = row
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        NSAttributedString(string: (component == 1) ? betaItems[row] : alphaItems[row],
                           attributes: [.foregroundColor: R.color.charcoal() ?? .purple])
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let textStyle = TextStyle.Style.header5
        let pickerLabel = (view as? UILabel) ?? UILabel()
        
        pickerLabel.font = UIFont(name: textStyle.fontName, size: textStyle.fontSize)
        pickerLabel.textAlignment = .center
        pickerLabel.text = (component == 1) ? betaItems[row] : alphaItems[row]
        
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
}

struct PickerField: UIViewRepresentable {
    // MARK: - Public properties
    @Binding var alphaIndex: Int?
    @Binding var betaIndex: Int?

    private var placeholder: String
    private var alphaItems: [String]
    private var betaItems: [String]
    private let textField: PickerTextField
    
    // MARK: - Initializers
    init<S>(_ title: S, items: [String], selectionIndex: Binding<Int?>) where S: StringProtocol {
        self.placeholder = String(title)
        self.alphaItems = items
        self.betaItems = []
        
        self._alphaIndex = selectionIndex
        self._betaIndex = .constant(nil)
        
        textField = PickerTextField(alphaItems: items,
                                    betaItems: [],
                                    alphaIndex: selectionIndex,
                                    betaIndex: .constant(nil))
    }
    
    init<S>(_ title: S, alphaItems: [String], betaItems: [String], alphaIndex: Binding<Int?>, betaIndex: Binding<Int?>) where S: StringProtocol {
        self.placeholder = String(title)
        self.alphaItems = alphaItems
        self.betaItems = betaItems
        
        self._alphaIndex = alphaIndex
        self._betaIndex = betaIndex
        
        textField = PickerTextField(alphaItems: alphaItems,
                                    betaItems: betaItems,
                                    alphaIndex: alphaIndex,
                                    betaIndex: betaIndex)
    }

    // MARK: - Public methods
    func makeUIView(context: UIViewRepresentableContext<PickerField>) -> UITextField {
        textField.placeholder = placeholder
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<PickerField>) {
        let style = TextStyle.Style.body1
        uiView.font = UIFont(name: style.fontName, size: style.fontSize)
        uiView.textColor = R.color.charcoal() ?? .purple
        
        switch (alphaIndex, betaIndex) {
        case (.some(let indexA), .none):
            uiView.text = alphaItems[indexA]
        case (.none, .some(let indexB)):
            uiView.text = betaItems[indexB]
        case (.some(let indexA), .some(let indexB)):
            uiView.text = alphaItems[indexA] + " " + betaItems[indexB]
        case (.none, .none):
            uiView.text = ""
        }
    }
}

// MARK: - Preview
struct PickerField_Previews: PreviewProvider {
    @State private static var selectedWeightIndex: Int?
    
    private static var weights: [String] = {
        var weightStrArr = ["n/a"]
        for weight in stride(from: 100, to: 355, by: 5) {
            weightStrArr.append("\(weight) lbs")
        }
        
        return weightStrArr
    }()
    
    static var previews: some View {
        Form {
            Section(header: Text("Enter your weight")) {
                PickerField("∞ lbs", items: weights, selectionIndex: $selectedWeightIndex)
            }
        }
    }
}
