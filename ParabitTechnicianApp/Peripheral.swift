//
//  Peripheral.swift
//  ParabitBeaconDemo
//
//  Created by Gurinder Singh on 10/4/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import CoreBluetooth

struct Peripheral {
    let name: String
    let UUID: String
    let isConnectable:Bool
    let sensorTag:CBPeripheral
}
