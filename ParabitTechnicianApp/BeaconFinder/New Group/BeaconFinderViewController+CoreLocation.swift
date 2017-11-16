//
//  BeaconFinderViewController+CoreLocation.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 11/16/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import CoreLocation

extension BeaconFinderViewController: CLLocationManagerDelegate  {
    
    func getBeaconRegion() -> CLBeaconRegion {
        let beaconRegion = CLBeaconRegion.init(proximityUUID: UUID.init(uuidString: "4390e0ec-e218-80b1-f34f-13a3f6fcb819")!,
                                               identifier: "Parabeacon")
        return beaconRegion
    }
    
    func startScanningForBeaconRegion(beaconRegion: CLBeaconRegion) {
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        let beacon = beacons.last
        
        print("Ranging")
    }
}
