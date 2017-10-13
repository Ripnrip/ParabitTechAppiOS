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
import SwiftSpinner

extension BeaconFinderViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - CBCentralManagerDelegate methods
    
    // MARK: - Update status methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            // 1
            keepScanning = true
            // 2
           // _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            // 3
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
            // 4
            SwiftSpinner.show("Scanning")
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
            BPStatusBarAlert(duration: 0.5, delay: 2.5, position: .statusBar) // customize duration, delay and position
                .message(message: "Bluetooth is turned off, please turn it on for the app")
                .messageColor(color: .white)
                .bgColor(color: .red)
                .completion { print("")}
                .show()
        }
    }
    
    // MARK: - Did discover peripherals
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey) and UUID is \(peripheral.identifier.uuidString)\"")
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            print("NEXT PERIPHERAL STATE: \(peripheral.state.rawValue)")
            if peripheralName == peripheralName {
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
                currentBeacon = paraDoor
                availableDoors.append(paraDoor)
                tableView.reloadData()
                
                centralManager.connect(sensorTag, options: nil)


                }else{
                //add peripheral to available doors tableview, but don't add the sensor, and set nil for sensortag, and false for isConnectable
                let paraDoor = Peripheral(name: peripheralName, UUID: peripheral.identifier.uuidString, isConnectable: false, sensorTag: nil)
                currentBeacon = paraDoor
                availableDoors.append(paraDoor)
                tableView.reloadData()
                SwiftSpinner.hide()
                    
                }
            }
        }
    }
    
    //MARK: Did connect to peripheral
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
    
    
    
    // MARK: - Did fail to connect
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("**** CONNECTION TO SENSOR TAG FAILED!!!")
    }

    // MARK: - Did discover services of a peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("there was an error discovering the services after connecting \(String(describing: error))")
        }
        guard let services = peripheral.services else {return}
        print("The discovered services are \(services))")
        
        services.forEach { (service) in
            if service.uuid.uuidString == eddystoneConfigurationServiceUUID {
                eddystoneService = service
            }
        }
        
        peripheral.discoverCharacteristics(nil, for: peripheral.services![0])
        
    }
    
    // MARK: - Did discover charachteristics of a service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("there was an error discovering characteristics for a service")
        }
        guard let characteristics = service.characteristics else {return}
        print("The discovered characteristics are \(characteristics))")
        

        characteristics.forEach { (characteristic) in
            switch characteristic.uuid.uuidString {
            case deviceInformationServiceUUID:
                deviceInformationCharacteristic = characteristic
            case advertisingInterval:
                advertisingIntervalCharacteristic = characteristic
            case radioTxPower:
                radioTxPowerCharacteristic = characteristic
            case "A3C87507-8ED3-4BDF-8A39-A01BEBEDE295":
                print("the unlock value is \(characteristic.value)")
            default:
                break
            }
            peripheral.readValue(for: characteristic)
            //peripheral.writeValue(<#T##data: Data##Data#>, for: <#T##CBDescriptor#>)
        }
    }
    
    // MARK: - Did update value for a characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("there was an error discovering the characteristics \(characteristic) from \(sensorTag)")
        }
        print("the updated values for characteristic is \(characteristic.uuid) with value \(characteristic.value)")
        if characteristic.uuid == CharacteristicID.lockState.UUID {
            print("****PARSE LOCK STATE VALUE****")
            parseLockStateValue()
        } else if characteristic.uuid == CharacteristicID.unlock.UUID {
            print("****UNLOCK BEACON****")
            unlockBeacon()
            //unlockBeaconWithCharacteristic(characteristic: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
            print("did write value for characteristic \(characteristic.uuid) with value \(characteristic.value)")
            if error != nil {
                print("there was an error while writing to the characteristis \(characteristic)")
            }
            sensorTag.readValue(for: characteristic)
            if characteristic.uuid == CharacteristicID.unlock.UUID {
                if let callback = lockStateCallback {
                    checkLockState(passkey: nil, lockStateCallback: callback)
                }
            } else if characteristic.uuid == CharacteristicID.lockState.UUID {
                if let callback = updateLockStateCallback {
                    lockStateCallback = callback
                    getUnlockChallenge()
                }
            } else if characteristic.uuid == CharacteristicID.factoryReset.UUID {
                if let callback = factoryResetCallback {
                    callback()
                }
            } else if characteristic.uuid == CharacteristicID.remainConnectable.UUID {
                if let callback = remainConnectableCallback {
                    callback()
                }
            }
        
    }

    
    // MARK: - Unlocking Beacon

    func parseLockStateValue() {
        if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.lockState.UUID),
            let value = characteristic.value {
            if value.count == 1 {
                let lockState = value.withUnsafeBytes { (ptr: UnsafePointer<Int>) in
                    ptr.pointee
                }
                if lockState == LockState.Locked.rawValue {
                    NSLog("The beacon is locked :( .")
                    didUpdateLockState(lockState: LockState.Locked)
                    unlockBeacon()
                    
//                    beginUnlockingBeacon(passKey: userPasskey!) { lockState in
//                        DispatchQueue.main.async {
//                            if lockState == LockState.Locked {
//                                /// User inserted a wrong password.
//                                print("wrong password")
//
//                            } else if lockState == LockState.Unlocked {
//                                /// The beacon is now unlocked!
//                                print("unlocked BEACON")
//                                //self.beaconPasskey = passkey
//                               // self.displayThrobber(message: "Reading slot data...")
//                                self.investigateBeacon()
//                            }
//                        }
//                    }
                    
                } else {
                    NSLog("The beacon is unlocked!")
                    didUpdateLockState(lockState: LockState.Unlocked)
                }
            }
        }
    }
    
    func didUpdateLockState(lockState: LockState) {
        if let callback = lockStateCallback {
            switch lockState {
            case LockState.Locked:
                if userPasskey != nil {
                    if didAttemptUnlocking {
                        callback(LockState.Locked)
                    } else {
                        getUnlockChallenge()
                    }
                } else {
                    callback(LockState.Locked)
                }
            case LockState.Unlocked:
                callback(LockState.Unlocked)
            default:
                callback(LockState.Unknown)
            }
        }
    }
    
    func checkLockState(passkey: String?,
                        lockStateCallback: @escaping (_ lockState: LockState) -> Void) {
        self.lockStateCallback = lockStateCallback
        if passkey != nil {
            userPasskey = passkey
        }
        if let lockStateCharacteristic = findCharacteristicByID(characteristicID: CharacteristicID.lockState.UUID) {
            sensorTag.readValue(for: lockStateCharacteristic)
        }
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
    
    func beginUnlockingBeacon(passKey: String,
                              lockStateCallback: @escaping (_ lockState: LockState) -> Void) {
        didAttemptUnlocking = false
        checkLockState(passkey: passKey, lockStateCallback: lockStateCallback)
        
    }
    
    func getUnlockChallenge() {
        if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.unlock.UUID) {
            sensorTag.readValue(for: characteristic)
        }
    }
    
    func unlockBeacon() {
        if let
            passKey = userPasskey,
            let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.unlock.UUID),
            let unlockChallenge = characteristic.value {
            let token: NSData? = AESEncrypt(data: unlockChallenge as NSData, key: passKey)
            // erase old password
            userPasskey = nil
            didAttemptUnlocking = true
            if let unlockToken = token {
                sensorTag.writeValue(unlockToken as Data,
                                      for: characteristic,
                                      type: CBCharacteristicWriteType.withResponse)
            }
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
            
            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                return cryptData as NSData
            } else {
                NSLog("Error: \(cryptStatus)")
            }
        }
        return nil
    }
    
    func writeNewLockCode(encryptedKey: NSData) {
        let value = NSMutableData(bytes: [0x00 as UInt8], length: 1)
        value.append(encryptedKey as Data)
        if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.lockState.UUID) {
            sensorTag.writeValue(value as Data, for: characteristic, type: .withResponse)
        }
    }
    
    func changeLockCode(oldCode: String, newCode: String, callback: @escaping (_ lockState: LockState) -> Void) {
        sensorTag.delegate = self
        updateLockStateCallback = callback
        
        let newCodeBytes = StringUtils.transformStringToByteArray(string: newCode)
        let newCodeData = NSData(bytes: newCodeBytes, length: newCodeBytes.count)
        let encryptedKey = AESEncrypt(data: newCodeData, key: oldCode)
        userPasskey = newCode
        if let key = encryptedKey {
            writeNewLockCode(encryptedKey: key)
        }
    }
    
    func factoryReset(callback: @escaping () -> Void) {
        factoryResetCallback = callback
        sensorTag.delegate = self
        if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.factoryReset.UUID) {
            let value = NSData(bytes: [0x0B as UInt8], length: 1)
            sensorTag.writeValue(value as Data, for: characteristic, type: .withResponse)
        }
    }
    
    func changeRemainConnectableState(on: Bool, callback: @escaping () -> Void) {
        remainConnectableCallback = callback
        sensorTag.delegate = self
        if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.remainConnectable.UUID) {
            var value: UInt8 = 0
            if on {
                value = 1
            }
            let data = NSData(bytes: [value], length: 1)
            sensorTag.writeValue(data as Data, for: characteristic, type: .withResponse)
        }
    }

    
    // MARK: - Did disconnect to a peripheral
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
