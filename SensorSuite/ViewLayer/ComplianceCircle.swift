//
//  ComplianceCircle.swift
//  SensorSuite
//
//  Created by Nguyen Bui on 12/27/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import SwiftUI

struct ComplianceCircle: View {
    @Binding var degree: Double
    
    private var currentPosition: PositionalFlagCategory
    private var complianceType: ComplianceType
    private var completionColor: Color
    private var circleColor: Color
    private let circleLineWidth: CGFloat = 30
    private var correctedDegree: CGFloat {
        return -1 * degree
    }

    @Injected(\.userDefaults) var userDefaults
    @Injected(\.rollCompliance) var rollCompliance

	var isNotComplying: Bool {
		if currentPosition == .left {
			return correctedDegree < minRollDegree(PositionalFlagCategory.left)
			|| correctedDegree > maxRollDegree(PositionalFlagCategory.partialLeft)
		}
		
		if currentPosition == .right {
			return correctedDegree > maxRollDegree(PositionalFlagCategory.right)
			|| correctedDegree < minRollDegree(PositionalFlagCategory.partialRight)
		}
		
		if currentPosition == .supine {
			return correctedDegree > maxRollDegree(PositionalFlagCategory.supine)
			|| correctedDegree < minRollDegree(PositionalFlagCategory.supine)
		}
		
		return true
	}
    
    enum ComplianceType {
        case roll
        case pitch
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Circle()
				.trim(
					from: minRollPercentage(currentPosition) - 0.1,
					to: maxRollPercentage(currentPosition) + 0.1
				)
                .stroke(lineWidth: circleLineWidth)
				.rotationEffect(Angle(degrees: 90))
                .foregroundColor(circleColor)
            if complianceType == .roll {
                if isNotComplying {
                    Circle()
                        .trim(from: redBoundFrom,
                              to: redBoundTo)
                        .stroke(style: StrokeStyle(lineWidth: circleLineWidth,
                                                   lineCap: .butt,
                                                   lineJoin: .round))
                        .foregroundColor(.red2Updated)
                        .rotationEffect(Angle(degrees: 90))
                }
                Circle()
                    .trim(from: minRollPercentage(currentPosition),
                          to: maxRollPercentage(currentPosition))
                    .stroke(style: StrokeStyle(lineWidth: circleLineWidth,
                                               lineCap: .butt,
                                               lineJoin: .round))
                    .foregroundColor(completionColor)
                    .rotationEffect(Angle(degrees: 90))
                if [.left, .right].contains(currentPosition) {
                    Circle()
                        .trim(from: yellowBoundFrom,
                              to: yellowBoundTo)
                        .stroke(style: StrokeStyle(lineWidth: circleLineWidth,
                                                   lineCap: .butt,
                                                   lineJoin: .round))
                        .foregroundColor(.yellow1)
                        .rotationEffect(Angle(degrees: 90))
                }
            }
        }
    }
    
    init(currentPosition: PositionalFlagCategory,
         complianceType: ComplianceType,
         completionColor: Color = .green3,
         circleColor: Color = .charcoal1.opacity(0.25),
         degree: Binding<Double>) {
        self.currentPosition = currentPosition
        self.complianceType = complianceType
        self.completionColor = completionColor
        self.circleColor = circleColor
        self._degree = degree
    }
}

// MARK: - Private
private extension ComplianceCircle {
    private func convertDegreeToPercentage(degree: CGFloat) -> CGFloat {
        let degree = min(degree + 180, 360.0)
        return (degree / 360.0)
    }

    private var redBoundFrom: CGFloat {
        if correctedDegree > maxRollDegree(currentPosition) {
            return maxRollPercentage(currentPosition)
        } else {
			return 0.25
        }
    }

    private var redBoundTo: CGFloat {
        if correctedDegree > maxRollDegree(currentPosition) {
			return  0.75
        } else {
            return minRollPercentage(currentPosition)
        }
    }

    private var yellowBoundFrom: CGFloat {
        if currentPosition == .left {
            return convertDegreeToPercentage(degree: -30)
        } else {
            return convertDegreeToPercentage(degree: userDefaults.complianceAngle!.partialAngleDegree)
        }
    }

    private var yellowBoundTo: CGFloat {
        if currentPosition == .left {
            return convertDegreeToPercentage(degree: -1 * userDefaults.complianceAngle!.partialAngleDegree)
        } else {
            return convertDegreeToPercentage(degree: 30)
        }
    }

    func minRollPercentage(_ flag: PositionalFlagCategory) -> CGFloat {
        let degree = min(minRollDegree(flag) + 180, 360.0)
        return CGFloat(degree / 360.0)
    }

    func maxRollPercentage(_ flag: PositionalFlagCategory) -> CGFloat {
        let degree = min(maxRollDegree(flag) + 180, 360.0)
        return CGFloat(degree / 360.0)
    }

    func minRollDegree(_ flag: PositionalFlagCategory) -> CGFloat {
        rollCompliance.targetRollDegree(flag).lowerBound
    }

    func maxRollDegree(_ flag: PositionalFlagCategory) -> CGFloat {
        rollCompliance.targetRollDegree(flag).upperBound
    }
}

struct ComplianceCircle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ComplianceCircle(currentPosition: .left,
                             complianceType: .roll,
                             degree: .constant(23))
                .frame(width: 96, height: 96)
                .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
            ComplianceCircle(currentPosition: .supine,
                             complianceType: .pitch,
                             degree: .constant(10))
                .frame(width: 96, height: 96)
                .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
            ComplianceCircle(currentPosition: .right,
                             complianceType: .roll,
                             degree: .constant(43))
                .frame(width: 96, height: 96)
                .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPhone8Plus()))
        }
    }
}
