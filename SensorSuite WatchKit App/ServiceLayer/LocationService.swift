//
//  LocationManager.swift
//  SensorSuite WatchKit App
//
//  Created by Vadym Riznychok on 3/4/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import CoreLocation

protocol LocationServiceProtocol: AnyObject {
    func requestAccess()
    func startLocationUpdate()
    func stopLocationUpdate()

    // unused
    // var location: CLLocation? { get }
}

extension Container {
    var locationService: Factory<LocationServiceProtocol> {
        self { LocationService.shared }.cached
    }
}

final class LocationService: NSObject, CLLocationManagerDelegate, LocationServiceProtocol {
    static let shared: LocationServiceProtocol = LocationService()
    private let locationManager = CLLocationManager()
    private(set) var location: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.allowsBackgroundLocationUpdates = true
        // TODO: Discuss with HQ and push later.
        // kCLLocationAccuracyReduced will be better to reduce battery consumption
        // this will keep the location services active
        // locationManager.pausesLocationUpdatesAutomatically = false
    }

    func requestAccess() {
        print("LocationService status: \(locationManager.authorizationStatus)")
        if locationManager.authorizationStatus != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startLocationUpdate() {
        locationManager.startUpdatingLocation()
    }

    func stopLocationUpdate() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // logger.debug("LocationService location updated: \(String(describing: locations.first?.altitude))")
        location = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.debug("LocationService did fail with error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        logger.debug("LocationService status: \(manager.authorizationStatus)")
    }
}
