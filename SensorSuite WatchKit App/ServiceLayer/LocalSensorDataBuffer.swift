//
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import SwiftUI

@propertyWrapper
struct MinDouble {
    private var number: Double

    init() { self.number = Double.infinity }

    mutating func reset() {
        number = Double.infinity
    }

    var wrappedValue: Double {
        get { return number }
        set { number = min(newValue, number) }
    }
}

@propertyWrapper
struct MaxDouble {
    private var number: Double

    init() { self.number = -Double.infinity }

    mutating func reset() {
        number = -Double.infinity
    }

    var wrappedValue: Double {
        get { return number }
        set { number = max(newValue, number) }
    }
}

final class LocalSensorDataBuffer: ObservableObject {
    @Published var dataPoints: [DataPoint] = []

    @MinDouble var minGravityX: Double
    @MinDouble var minGravityY: Double
    @MinDouble var minGravityZ: Double

    @MaxDouble var maxGravityX: Double
    @MaxDouble var maxGravityY: Double
    @MaxDouble var maxGravityZ: Double

    @Injected(\.notificationCenter) private var notificationCenter

    init() {
        notificationCenter.addObserver(
            self,
            selector: #selector(self.newRawData),
            name: DeviceMotionManager.newDataNote,
            object: nil
        )
    }

    convenience init(seedData: [DataPoint]) {
        self.init()

        self.dataPoints.append(contentsOf: seedData)
    }

    func reset() {
        dataPoints.removeAll(keepingCapacity: true)

        _minGravityX.reset()
        _minGravityY.reset()
        _minGravityZ.reset()

        _maxGravityX.reset()
        _maxGravityY.reset()
        _maxGravityZ.reset()
    }

    @objc
    func newRawData(notification: NSNotification) {
        // Updates should happen on UI thread to avoid issues
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let data = notification.userInfo as? [String: DataPoint],
                  let accelData = data["data"] else {
                return
            }

            if self.dataPoints.count > 49 {
                self.dataPoints.remove(at: 0)
            }

            self.minGravityX = accelData.xGravity
            self.minGravityY = accelData.yGravity
            self.minGravityZ = accelData.zGravity

            self.maxGravityX = accelData.xGravity
            self.maxGravityY = accelData.yGravity
            self.maxGravityZ = accelData.zGravity

            self.dataPoints.append(accelData)
        }
    }
}
