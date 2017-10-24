//
//  BeaconTabBarController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/7/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import CoreBluetooth

class BeaconTabBarController: UITabBarController {
    
    var currentBeacon:Peripheral?
    var eddystoneService: CBService?
    
    var centralManager              : CBCentralManager?
    var selectedPeripheral          : CBPeripheral?
    var selectedPeripheralIsSecure  : Bool?
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

    }


}
