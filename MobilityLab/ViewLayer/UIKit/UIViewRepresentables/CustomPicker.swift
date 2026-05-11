//
//  CustomPicker.swift
//  MobilityLab
//
//  Created by Vadym Riznychok on 5/11/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI
import UIKit

struct CustomPicker<Element: Equatable>: UIViewRepresentable {
    var dataArray: [Element]
    @Binding var selected: Element
	var fontSize: CGFloat = 16
	
    func makeCoordinator() -> CustomPicker.Coordinator {
		return CustomPicker.Coordinator(self, self.fontSize)
    }

    func makeUIView(context: UIViewRepresentableContext<CustomPicker>) -> UIPickerView {
        let picker = UIPickerView(frame: .zero)
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        picker.setContentHuggingPriority(.defaultLow, for: .horizontal)
        picker.translatesAutoresizingMaskIntoConstraints = false
        if let index = dataArray.firstIndex(of: selected) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        return picker
    }

    func updateUIView(_ view: UIPickerView, context: UIViewRepresentableContext<CustomPicker>) {
        view.reloadAllComponents()
    }

    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: CustomPicker
		let fontSize: CGFloat
		
		init(_ pickerView: CustomPicker, _ fontSize: CGFloat) {
            self.parent = pickerView
			self.fontSize = fontSize
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return parent.dataArray.count
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            return pickerView.frame.size.width
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            return 32
        }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            updateBackground(pickerView)

            let view = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.size.width, height: 32))

            let pickerLabel = UILabel(frame: view.bounds)

            pickerLabel.text = "\(parent.dataArray[row])"

            pickerLabel.adjustsFontSizeToFitWidth = true
            pickerLabel.textAlignment = .center
            pickerLabel.lineBreakMode = .byWordWrapping
            pickerLabel.numberOfLines = 0
            pickerLabel.textColor = UIColor(Color.charcoal1)
            pickerLabel.font = UIFont(name: "Avenir-Roman", size: fontSize)

            view.addSubview(pickerLabel)

            return view
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
			guard row < parent.dataArray.count else { return }
            parent.selected = parent.dataArray[row]
        }

        func updateBackground(_ pickerView: UIPickerView) {
            if let backgroundView = pickerView.subviews.first(where: { $0.backgroundColor == .quaternarySystemFill }) {
                backgroundView.backgroundColor = UIColor(Color.indigo5)
            }

            if let backgroundView = pickerView.subviews.first(where: { $0.backgroundColor == UIColor(Color.indigo5) }) {
                pickerView.sendSubviewToBack(backgroundView)
                backgroundView.layer.cornerRadius = 0
                var frame = backgroundView.frame
                frame.size.width = pickerView.frame.size.width
                frame.origin.x = 0
                backgroundView.frame = frame
            }
        }
    }
}
