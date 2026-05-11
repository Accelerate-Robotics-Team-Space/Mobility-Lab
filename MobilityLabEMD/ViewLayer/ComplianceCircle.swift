//
//  ComplianceCircle.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/24/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ComplianceCircle: View {
    @EnvironmentObject var turningProtocol: TurningProtocol
    var degree: Double

    private var completionColor: Color
    private var circleColor: Color
    private var circleLineWidth: CGFloat = 30
    private var targetPosition: PositionalFlagCategory

    private var correctedDegree: CGFloat {
        return -1 * CGFloat(degree)
    }

	var isNotComplying: Bool {
		if targetPosition == .left {
			return correctedDegree < minRollDegree(.left)
            || correctedDegree > maxRollDegree(.partialLeft)
		}
		
		if targetPosition == .right {
			return correctedDegree > maxRollDegree(.right)
            || correctedDegree < minRollDegree(.partialRight)
		}
		
		if targetPosition == .supine {
			return correctedDegree > maxRollDegree(.supine)
			|| correctedDegree < minRollDegree(.supine)
		}
		
		return true
	}
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Circle()
                .trim(
                    from: minRollPercentage(targetPosition) - 0.1,
                    to: maxRollPercentage(targetPosition) + 0.1
                )
                .stroke(lineWidth: circleLineWidth)
                .rotationEffect(Angle(degrees: 90))
                .foregroundColor(circleColor)
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
                .trim(from: minRollPercentage(targetPosition),
                      to: maxRollPercentage(targetPosition))
                .stroke(style: StrokeStyle(lineWidth: circleLineWidth,
                                           lineCap: .butt,
                                           lineJoin: .round))
                .foregroundColor(completionColor)
                .rotationEffect(Angle(degrees: 90))
            if [.left, .right].contains(targetPosition) {
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

    private func minRollDegree() -> CGFloat {
        return minRollDegree(targetPosition)
    }

    private func maxRollDegree() -> CGFloat {
        return maxRollDegree(targetPosition)
    }
    
    init(completionColor: Color = .green2,
         circleColor: Color = .charcoal4,
         circleLineWidth: CGFloat = 8,
         degree: Double,
         targetPosition: PositionalFlagCategory?) {
        self.completionColor = completionColor
        self.circleColor = circleColor
        self.circleLineWidth = circleLineWidth
        self.degree = degree
        self.targetPosition = targetPosition ?? .supine
    }
}

// MARK: - Private
private extension ComplianceCircle {
    func convertDegreeToPercentage(degree: CGFloat) -> CGFloat {
        let degree = min(degree + 180, 360.0)
        return (degree / 360.0)
    }

    private var redBoundFrom: CGFloat {
        if correctedDegree > maxRollDegree(targetPosition) {
            return maxRollPercentage(targetPosition)
        } else {
			return 0.25
        }
    }

    private var redBoundTo: CGFloat {
        if correctedDegree > maxRollDegree(targetPosition) {
			return 0.75
        } else {
			return minRollPercentage(targetPosition)
        }
    }

    private var yellowBoundFrom: CGFloat {
        if targetPosition == .left {
            return convertDegreeToPercentage(degree: -30)
        } else {
            return convertDegreeToPercentage(degree: turningProtocol.complianceAngle.partialAngleDegree)
        }
    }

    private var yellowBoundTo: CGFloat {
        if targetPosition == .left {
            return convertDegreeToPercentage(degree: -1 * turningProtocol.complianceAngle.partialAngleDegree)
        } else {
            return convertDegreeToPercentage(degree: 30)
        }
    }
}

private extension ComplianceCircle {
    func minRollPercentage(_ pos: PositionalFlagCategory) -> CGFloat {
        let degree = min(minRollDegree(pos) + 180, 360)
        return CGFloat(degree / 360.0)
    }

    func maxRollPercentage(_ pos: PositionalFlagCategory) -> CGFloat {
        let degree = min(maxRollDegree(pos) + 180, 260)
        return CGFloat(degree / 360.0)
    }

    func minRollDegree(_ pos: PositionalFlagCategory) -> CGFloat {
        return turningProtocol.targetRollDegree(pos).lowerBound
    }

    func maxRollDegree(_ pos: PositionalFlagCategory) -> CGFloat {
        return turningProtocol.targetRollDegree(pos).upperBound
    }
}

struct ComplianceCircle_Previews: PreviewProvider {
    static var previews: some View {
        ComplianceCircle(degree: 180, targetPosition: .supine)
            .frame(width: 56, height: 56)
            .previewDevice(PreviewDevice(rawValue: R.string.localizable.iPadAirEMD()))
            .environmentObject(TurningProtocol())
    }
}
