//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

@testable import SensorSuite_BMM
import SwiftUI
import XCTest

final class HeadOfBedImageMapperTests: XCTestCase {
    // MARK: - Mapping / Rounding
    func test_getHeadOfBedDegree_roundsAndBoundsCorrectly() {
        // GIVEN - a set of representative input values
        let inputs: [(Double, HeadOfBedDegreeImageMapper)] = [
            (-10.0, .zero),   // below zero is clamped to zero
            (0.0, .zero),
            (2.4, .zero),     // rounds to 0
            (2.5, .five),     // rounds to 5
            (5.0, .five),
            (7.4, .five),
            (7.5, .ten),
            (14.9, .fifteen),
            (15.1, .fifteen),
            (29.9, .thirty),
            (30.0, .thirty),
            (44.9, .fortyFive),
            (45.0, .fortyFive),
            (59.9, .sixty),
            (60.0, .sixty),
            (74.9, .seventyFive),
            (75.0, .seventyFive),
            (87.4, .eightyFive),
            (87.5, .ninetyDegree),
            (90.0, .ninetyDegree),
            (92.0, .ninetyDegree), // anything above 90 falls back to .ninetyDegree via rawValue init
        ]

        // WHEN - mapping each input
        // THEN - verify expected enum case is returned
        for (value, expected) in inputs {
            let result = HeadOfBedDegreeImageMapper.getHeadOfBedDegree(value)
            XCTAssertEqual(result, expected, "Expected rounding of \(value) to be \(expected), got \(result)")
        }
    }

    func test_mapping_isDefinedForEveryWholeDegree_0_through_100() {
        // GIVEN - the full integer range from 0 to 100
        // WHEN - mapping each value
        // THEN - we always get a valid case and a non-empty image name
        for value in 0...100 {
            let result = HeadOfBedDegreeImageMapper.getHeadOfBedDegree(Double(value))
            // Sanity: result must be one of the known cases
            XCTAssertTrue(allCases.contains(result), "Unexpected case for value: \(value): \(result)")
            // Image name should be non-empty
            let name = result.getImageName()
            XCTAssertFalse(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Image name should not be empty for case: \(result)")
        }
    }

    // MARK: - Image name and Image creation
    func test_getImageName_isNonEmpty_forAllCases() {
        let names = [
            "zero-degree",
            "five-degree",
            "ten-degree",
            "fifteen-degree",
            "twenty-degree",
            "twenty-five-degree",
            "thirty-degree",
            "thirty-five-degree",
            "forty-degree",
            "forty-five-degree",
            "fifty-degree",
            "fifty-five-degree",
            "sixty-degree",
            "sixty-five-degree",
            "seventy-degree",
            "seventy-five-degree",
            "eighty-degree",
            "eighty-five-degree",
            "ninety-degree",
        ]

        // GIVEN - all enum cases
        for (name, testCase) in zip(names, allCases) {
            // WHEN - retrieving image names
            let imgName = testCase.getImageName()
            // THEN - names are non-empty strings
            XCTAssertFalse(imgName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Image name should not be empty for case: \(testCase)")
            XCTAssertEqual(name, imgName)
        }
    }

    // A canonical ordered list of all supported degrees in the mapper.
    // If new degrees are added to HeadOfBedDegreeImageMapper, update this list to keep coverage high.
    private let allCases: [HeadOfBedDegreeImageMapper] = [
        .zero, .five, .ten, .fifteen, .twenty, .twentyFive, .thirty, .thirtyFive,
        .forty, .fortyFive, .fifty, .fiftyFive, .sixty, .sixtyFive, .seventy, .seventyFive,
        .eighty, .eightyFive, .ninetyDegree,
    ]
}
