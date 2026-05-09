//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftUI

enum HeadOfBedDegreeImageMapper: Int {
	case zero = 0
	case five = 5
	case ten = 10
	case fifteen = 15
	case twenty = 20
	case twentyFive = 25
	case thirty = 30
	case thirtyFive = 35
	case forty = 40
	case fortyFive = 45
	case fifty = 50
	case fiftyFive = 55
	case sixty = 60
	case sixtyFive = 65
	case seventy = 70
	case seventyFive = 75
	case eighty = 80
	case eightyFive = 85
	case ninetyDegree = 90
	
    static func getHeadOfBedDegree(_ value: Double) -> HeadOfBedDegreeImageMapper {
        guard value >= 0 else { return .zero }
        let rounded = Int((value / 5).rounded() * 5)
        return HeadOfBedDegreeImageMapper(rawValue: rounded) ?? .ninetyDegree
	}
	
	func getImageName() -> String {
		switch self {
		case .zero:
			return R.image.zeroDegree.name
		case .five:
			return R.image.fiveDegree.name
		case .ten:
			return R.image.tenDegree.name
		case .fifteen:
			return R.image.fifteenDegree.name
		case .twenty:
			return R.image.twentyDegree.name
		case .twentyFive:
			return R.image.twentyFiveDegree.name
		case .thirty:
			return R.image.thirtyDegree.name
		case .thirtyFive:
			return R.image.thirtyFiveDegree.name
		case .forty:
			return R.image.fortyDegree.name
		case .fortyFive:
			return R.image.fortyFiveDegree.name
		case .fifty:
			return R.image.fiftyDegree.name
		case .fiftyFive:
			return R.image.fiftyFiveDegree.name
		case .sixty:
			return R.image.sixtyDegree.name
		case .sixtyFive:
			return R.image.sixtyFiveDegree.name
		case .seventy:
			return R.image.seventyDegree.name
		case .seventyFive:
			return R.image.seventyFiveDegree.name
		case .eighty:
			return R.image.eightyDegree.name
		case .eightyFive:
			return R.image.eightyFiveDegree.name
		case .ninetyDegree:
			return R.image.ninetyDegree.name
		}
	}

    static func imageName(_ degrees: Double) -> String {
        let mapped = HeadOfBedDegreeImageMapper.getHeadOfBedDegree(degrees)
        return mapped.getImageName()
    }
}
