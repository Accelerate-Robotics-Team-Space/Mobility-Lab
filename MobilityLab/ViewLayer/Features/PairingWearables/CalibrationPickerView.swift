//
//  CalibrationPickerView.swift
//  MobilityLab BMM
//
//  Created by Deepika Ramesh on 12/21/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct CalibrationPickerView: View {
	var degrees: [Int]
	@State var selectedAngle: Int = 0
	@Binding var angle: Double
	@Binding var lastAngle: Double
	@Binding var showPickerView: Bool
	
    var body: some View {
		VStack {
			HStack {
				Spacer()
				Button {
					angle = Double(selectedAngle)
					lastAngle = angle
					showPickerView = false
				} label: {
					Text("Done")
						.bold()
						.font(.custom("Avenir-Heavy", size: 16))
						.foregroundColor(Color.charcoal)
				}
			}
			.padding()
			CustomPicker(dataArray: degrees, selected: $selectedAngle, fontSize: 24)
		}
    }
}

struct CalibrationPickerView_Previews: PreviewProvider {
    static var previews: some View {
		CalibrationPickerView(
			degrees: [Int](0...90),
			angle: .constant(25),
			lastAngle: .constant(25),
			showPickerView: .constant(true)
		)
    }
}
