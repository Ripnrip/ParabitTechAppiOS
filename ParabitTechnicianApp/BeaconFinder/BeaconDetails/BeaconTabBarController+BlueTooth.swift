//
//  BeaconTabBarController+BlueTooth.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/13/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BeaconTabBarController: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }
    
    // MARK: - Did discover charachteristics of a service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("there was an error discovering characteristics for a service")
        }
        guard let characteristics = service.characteristics else {return}
        print("The discovered characteristics are \(characteristics))")
        
        
        characteristics.forEach { (characteristic) in
//            switch characteristic.uuid.uuidString {
//            case deviceInformationServiceUUID:
//                deviceInformationCharacteristic = characteristic
//            case advertisingInterval:
//                advertisingIntervalCharacteristic = characteristic
//            case radioTxPower:
//                radioTxPowerCharacteristic = characteristic
//            default:
//                break
            peripheral.readValue(for: characteristic)
            }
            //peripheral.writeValue(<#T##data: Data##Data#>, for: <#T##CBDescriptor#>)
        
    }
    
    // MARK: - Did update value for a characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("there was an error discovering the characteristics \(characteristic) from \(peripheral)")
        }
        print("the updated values for characteristic post-unlock is \(characteristic)")
        
        
    }

    
}
