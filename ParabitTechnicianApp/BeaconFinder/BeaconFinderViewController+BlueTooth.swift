//
//  BeaconFinderViewController+BlueTooth.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/10/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import BPStatusBarAlert

extension BeaconFinderViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - CBCentralManagerDelegate methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            // 1
            keepScanning = true
            // 2
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            // 3
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        case .unknown:
            print("Bluetooth is unknown")
        case .resetting:
            print("Bluetooth is resetting; a state update is pending.")
        case .unsupported:
            print("Bluetooth is unsupported")
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .poweredOff:
            print("Bluetooth is powered off")
        }
    }
    
    /*
     Invoked when the central manager discovers a peripheral while scanning.
     
     The advertisement data can be accessed through the keys listed in Advertisement Data Retrieval Keys.
     You must retain a local copy of the peripheral if any command is to be performed on it.
     In use cases where it makes sense for your app to automatically connect to a peripheral that is
     located within a certain range, you can use RSSI data to determine the proximity of a discovered
     peripheral device.
     
     central - The central manager providing the update.
     peripheral - The discovered peripheral.
     advertisementData - A dictionary containing any advertisement data.
     RSSI - The current received signal strength indicator (RSSI) of the peripheral, in decibels.
     */
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey) and UUID is \(peripheral.identifier.uuidString)\"")
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            print("NEXT PERIPHERAL STATE: \(peripheral.state.rawValue)")
            if peripheralName == AvailableDoorsViewController.sensorTagName {
                print("SENSOR TAG FOUND! ADDING NOW!!!")
                // to save power, stop scanning for other devices
                keepScanning = false
                pauseScan()
                
                //determine if beacon is connectablee
                guard let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as? Bool else {return}
                print("the Parabeacon's configuration state is \(isConnectable)")
                
                if Bool(isConnectable) {

                // save a reference to the sensor tag
                sensorTag = peripheral
                sensorTag.delegate = self
                
                
                //add peripheral to available doors tableview
                let paraDoor = Peripheral(name: peripheralName, UUID: peripheral.identifier.uuidString, isConnectable: true, sensorTag: sensorTag)
                availableDoors.append(paraDoor)
                tableView.reloadData()
                
                //connect -- Moved to the Didselect tableview method
                //centralManager.connect(sensorTag, options: nil)
                    
                }else{
                //add peripheral to available doors tableview, but don't add the sensor, and set nil for sensortag
                let paraDoor = Peripheral(name: peripheralName, UUID: peripheral.identifier.uuidString, isConnectable: false, sensorTag: nil)
                availableDoors.append(paraDoor)
                tableView.reloadData()
                }
            }
        }
    }
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     
     This method is invoked when a call to connectPeripheral:options: is successful.
     You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    

    // Discover services of the peripheral
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!")
        
        BPStatusBarAlert(duration: 0.1, delay: 2, position: .statusBar) // customize duration, delay and position
            .message(message: "Successfully connected to the device")
            .messageColor(color: .white)
            .bgColor(color: .green)
            .completion { print("")}
            .show()
        
        // Now that we've successfully connected to the SensorTag, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        peripheral.discoverServices(nil)
    }
    
    
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     This method is invoked when a connection initiated via the connectPeripheral:options: method fails to complete.
     Because connection attempts do not time out, a failed connection usually indicates a transient issue,
     in which case you may attempt to connect to the peripheral again.
     */
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("**** CONNECTION TO SENSOR TAG FAILED!!!")
    }
    
    /*
     Invoked after connecting to a peripheral; didDiscoverServices lists the services
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("there was an error discovering the services after connecting \(String(describing: error))")
        }
        guard let services = peripheral.services else {return}
        print("The discovered services are \(services))")
        peripheral.discoverCharacteristics(nil, for: peripheral.services![0])
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("there was an error discovering characteristics for a service")
        }
        guard let characteristics = service.characteristics else {return}
        print("The discovered characteristics are \(characteristics))")
        characteristics.forEach { (characteristic) in
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("there was an error discovering the characteristics \(characteristic) from \(sensorTag)")
        }
        //print("the updated values for characteristic \(characteristic)")
        if characteristic.uuid == CharacteristicID.lockState.UUID {
            print("****PARSE LOCK STATE VALUE****")
            parseLockStateValue()
        } else if characteristic.uuid == CharacteristicID.unlock.UUID {
            print("****UNLOCK BEACON****")
            unlockBeaconWithCharacteristic(characteristic: characteristic)
        }
    }
    
    func parseLockStateValue() {
        if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.lockState.UUID),
            let value = characteristic.value {
            if value.count == 1 {
                let lockState = value.withUnsafeBytes { (ptr: UnsafePointer<Int>) in
                    ptr.pointee
                }
                if lockState == LockState.Locked.rawValue {
                    NSLog("The beacon is locked :( .")
                    
                } else {
                    NSLog("The beacon is unlocked!")
                    
                }
            }
        }
    }
    
    func unlockBeaconWithCharacteristic(characteristic:CBCharacteristic) {
        print("the value of the characteristic is \(characteristic)")
        guard let unlockChallenge = characteristic.value else {return}
        let token: NSData? = AESEncrypt(data: unlockChallenge as NSData, key: userPasskey)
        // erase old password
        userPasskey = nil
        didAttemptUnlocking = true
        if let unlockToken = token {
            sensorTag.writeValue(unlockToken as Data,
                                            for: characteristic,
                                            type: CBCharacteristicWriteType.withResponse)
        }
        
    }
    
    func AESEncrypt(data: NSData, key: String?) -> NSData? {
        if let passKey = key {
            let keyBytes = StringUtils.transformStringToByteArray(string: passKey)
            let cryptData = NSMutableData(length: Int(data.length) + kCCBlockSizeAES128)!
            let operation: CCOperation = UInt32(kCCEncrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
            let options:   CCOptions   = UInt32(kCCOptionECBMode)
            var numBytesEncrypted :size_t = 0
            let cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      keyBytes,
                                      keyBytes.count,
                                      nil,
                                      data.bytes,
                                      data.length,
                                      cryptData.mutableBytes,
                                      cryptData.length,
                                      &numBytesEncrypted)
            
            if Int(cryptStatus) == Int(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                return cryptData as NSData
            } else {
                NSLog("Error: \(cryptStatus)")
                
            }
        }
        return nil
    }
    
    
    func findCharacteristicByID(characteristicID: CBUUID) -> CBCharacteristic? {
        if let services = sensorTag.services {
            for service in services {
                for characteristic in service.characteristics! {
                    if characteristic.uuid == characteristicID {
                        return characteristic
                    }
                }
            }
        }
        return nil
    }
    
    
    /*
     Invoked when an existing connection with a peripheral is torn down.
     
     This method is invoked when a peripheral connected via the connectPeripheral:options: method is disconnected.
     If the disconnection was not initiated by cancelPeripheralConnection:, the cause is detailed in error.
     After this method is called, no more methods are invoked on the peripheral device’s CBPeripheralDelegate object.
     
     Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("**** DISCONNECTED FROM SENSOR TAG!!!")
        
        if error != nil {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        sensorTag = nil
        availableDoors = availableDoors.filter {$0.sensorTag != sensorTag}
        tableView.reloadData()
        
    }
    
    
    // MARK: - Bluetooth scanning
    
    @objc func pauseScan() {
        // Scanning uses up battery on phone, so pause the scan process for the designated interval.
        print("*** PAUSING SCAN...")
        _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(resumeScan), userInfo: nil, repeats: false)
        centralManager.stopScan()
        //allow user to disconnect with some UI
    }
    
    @objc func resumeScan() {
        if keepScanning {
            // Start scanning again...
            print("*** RESUMING SCAN!")
            
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            //allow user to disconnect with some UI
        }
    }
    
}
