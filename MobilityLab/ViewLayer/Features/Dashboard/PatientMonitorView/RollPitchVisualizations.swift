//
//  RollPitchVisualizations.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 4/5/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct RollPitchVisualizations: View {
    @EnvironmentObject var patientMonitorDriver: PatientMonitorDriver
    
    @State private var rollDegree: Double = 0.0
    @State private var pitchDegree: Double = 0.0
    
    var body: some View {
			HStack(alignment: .top, spacing: 62) {
				VStack {
					ZStack(alignment: .top) {
						ComplianceCircle(
							currentPosition: patientMonitorDriver.desiredPosition,
							complianceType: .roll,
							circleColor: .charcoal4,
							degree: $rollDegree
						)
						.frame(width: 160, height: 160)
						VStack {
							Image(R.image.pointerPatientBed.name)
								.resizable()
								.frame(width: 69, height: 80)
								.scaledToFit()
								.rotationEffect(.degrees(-rollDegree), anchor: .bottom)
							Text("Turn Position")
								.font(.custom("Avenir-Heavy", size: 16))
								.foregroundColor(.charcoal1)
								.padding(.top, 18)

                            // Textual representation of patient turn angle. eg " 37°"
                            Text(
                                String(
                                    format: " %d\u{00B0}", // u{00B0} = '°' degree symbol

                                    // Angle argument identical to `PatientMonitorDriver` `var turnAngle: Int`,
                                    // but only taking the magnitude to avoid negatives being displayed for right turns
                                    Int(rollDegree.rounded().magnitude)
                                )
                            )
							.transition(.opacity)
						}
					}
					.onReceive(patientMonitorDriver.$rollDegree) { rollDegree in
						withAnimation(.linear(duration: 0.2)) {
							self.rollDegree = rollDegree
						}
					}
				}
				VStack {
                    HeadOfBedImage(angle: pitchDegree, target: patientMonitorDriver.desiredPosition)
                        .frame(height: 90)
					Text("Head of Patient")
						.font(.custom("Avenir-Heavy", size: 16))
						.foregroundColor(.charcoal1)
						.padding(.top, 3)
                        .background(.white.opacity(shadowOpacity))
                        .shadow(color: .white.opacity(shadowOpacity), radius: 10, x: 0, y: 10)
                        .padding(.top, 5)

                    // Textual representation of 'Head of Patient' angle. eg "2°"
                    Text(
                        String(
                            format: "%d\u{00B0}", // u{00B0} = '°' degree symbol

                            // Angle argument identical to `PatientMonitorDriver` `var headOfBedAngle: Int`
                            Int(pitchDegree.rounded())
                        )
                    )
                    .background(.white.opacity(shadowOpacity))
                    .transition(.opacity)
                    .shadow(color: .white.opacity(shadowOpacity), radius: 10, x: 0, y: 10)
				}
				.onReceive(patientMonitorDriver.$pitchDegree) { pitchDegree in
					withAnimation(.linear(duration: 0.2)) {
						self.pitchDegree = pitchDegree
					}
				}
			}
			.padding([.leading, .trailing], 20)
    }

    private var shadowOpacity: CGFloat { 0.8 }
}

struct RollPitchVisualizations_Previews: PreviewProvider {
    static var previews: some View {
        RollPitchVisualizations()
            .environmentObject(PatientMonitorDriver())
    }
}
