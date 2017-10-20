//
//  BeaconFinderViewController+BlueTooth.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/10/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
///

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
            SwiftSpinner.show(duration: 4, title: "Scanning")
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
            BPStatusBarAlert(duration: 0.5, delay: 2.5, position: .statusBar)
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
                    currentBeacon = Peripheral(name: peripheralName, UUID: peripheral.identifier.uuidString, isConnectable: true, sensorTag: sensorTag, isUnlocked: nil, deviceInformationCharacteristic: nil, advertisingIntervalCharacteristic: nil, radioTxPowerCharacteristic: nil, advSlotDataCharacteristic: nil, firmwareRevisionString: nil, advertisingValue: nil)
                guard let door = currentBeacon else {return}
                availableDoors.append(door)
                tableView.reloadData()
                
                centralManager.connect(sensorTag, options: nil)


                }else{
                //add peripheral to available doors tableview, but don't add the sensor, and set nil for sensortag, and false for isConnectable
                    currentBeacon = Peripheral(name: peripheralName, UUID: peripheral.identifier.uuidString, isConnectable: false, sensorTag: sensorTag, isUnlocked: nil, deviceInformationCharacteristic: nil, advertisingIntervalCharacteristic: nil, radioTxPowerCharacteristic: nil, advSlotDataCharacteristic: nil, firmwareRevisionString: nil, advertisingValue: nil)
                guard let door = currentBeacon else {return}
                availableDoors.append(door)
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
        //print("The discovered services are \(services))")
        
        services.forEach { (service) in
            switch service.uuid.uuidString {
                case eddystoneConfigurationServiceUUID:
                     eddystoneService = service
                case deviceInformationServiceUUID:
                     deviceInformationService = service
                default:
                     break
            }
            print("The discovered service is \(service) with UUID \(service.uuid.uuidString)")
        }
        guard let eddyStoneService = eddystoneService, let deviceInfoService = deviceInformationService else { return }
        beaconInvestigation = BeaconInvestigation(peripheral: sensorTag)
        
        peripheral.discoverCharacteristics(nil, for: eddyStoneService)
    }
    
    // MARK: - Did discover charachteristics of a service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("there was an error discovering characteristics for a service")
        }
        guard let characteristics = service.characteristics else {return}
        print("The discovered characteristics are \(characteristics))")
        
        if service == deviceInformationService {
            print("the device information service characteristics are \(characteristics)")
            
        }

        characteristics.forEach { (characteristic) in
            switch characteristic.uuid.uuidString {
            case advertisingInterval:
                currentBeacon?.advertisingIntervalCharacteristic = characteristic
            case radioTxPower:
                currentBeacon?.radioTxPowerCharacteristic = characteristic
            case advSlotData:
                currentBeacon?.advSlotDataCharacteristic = characteristic
            case unlockUUID:
                print("the unlock value is \(characteristic.value)")
            default:
                break
            }
            peripheral.readValue(for: characteristic)
        }
    }
    
    // MARK: - Did update value for a characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("there was an error discovering the characteristics \(characteristic) from \(sensorTag)")
        }

        
        if isBeaconUnlocked {

                print("the updated values for characteristic is \(characteristic.uuid) with value \(characteristic.value) ")
            
                //2A26 is firmware revision string .uuidString
            if characteristic.uuid.uuidString == "2A26" {
                guard let value = characteristic.value , let datastring = NSString(data: value, encoding: String.Encoding.utf8.rawValue) else { return }
                currentBeacon?.firmwareRevisionString = datastring as String
                
            }
            
                switch characteristic.uuid {
                case CharacteristicID.capabilities.UUID:
                    beaconInvestigation?.didReadBroadcastCapabilities()
                case CharacteristicID.ADVSlotData.UUID:
                    print("Found the ADVSlotData ID \(characteristic) and properties \(characteristic.properties) and descriptors \(characteristic.descriptors)")
                    beaconInvestigation?.didReadSlotData()
                case CharacteristicID.radioTxPower.UUID:
                    print("Found the radioTxPower ID \(characteristic)")
                    beaconInvestigation?.didReadTxPower()
                    currentBeacon?.radioTxPowerCharacteristic = characteristic
                case CharacteristicID.advertisingInterval.UUID:
                    print("Found the Advertising Characteristic ID \(characteristic)")
                    currentBeacon?.advertisingValue = beaconInvestigation?.didReadAdvertisingInterval()
                    currentBeacon?.advertisingIntervalCharacteristic = characteristic
                case CharacteristicID.remainConnectable.UUID:
                    beaconInvestigation?.didReadRemainConnectableState()
                    guard let slotData = beaconInvestigation?.slotData else { break }
                    print("the beacon slot data values are \(slotData)")
                    
                    // lets try writing here
//                    let dataString = "012C"
//                    let data = dataString.hexadecimal()
//                    peripheral.writeValue(data!, for: (currentBeacon?.advertisingIntervalCharacteristic!)!, type: CBCharacteristicWriteType.withResponse)
                default:
                    return
                }
            
            }else{
                switch characteristic.uuid {
                case CharacteristicID.lockState.UUID:
                    print("****PARSE LOCK STATE VALUE****")
                    parseLockStateValue()
                case CharacteristicID.unlock.UUID:
                    print("****UNLOCK BEACON****")
                    unlockBeacon()
                default:
                    return
                }
            }


    }
    
    // MARK: - Did write value for a characteristic
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
            print("did write value for characteristic \(characteristic.uuid) with value \(characteristic.value)")
            if error != nil {
                print("there was an error while writing to the characteristis \(characteristic)")
            }
        
            if characteristic.uuid == CharacteristicID.advertisingInterval.UUID {
                sensorTag.readValue(for: characteristic)
            }
        
            if characteristic.uuid == CharacteristicID.radioTxPower.UUID {
                sensorTag.readValue(for: characteristic)
                
            }
        
            //sensorTag.readValue(for: advertisingIntervalCharacteristic!)
            if characteristic.uuid == CharacteristicID.unlock.UUID {
                //Wrote to the unlock characteristic, the other values should be ready
                SwiftSpinner.hide()
                isBeaconUnlocked = true
                
                
                guard let advSlotChar = currentBeacon?.advSlotDataCharacteristic else { return }
                sensorTag.readValue(for: advSlotChar)

                //let deviceInfoChar = currentBeacon?.deviceInformationCharacteristic sensorTag.readValue(for: deviceInfoChar)

                guard let deviceInfoService = deviceInformationService else { return }
                peripheral.discoverCharacteristics(nil, for: deviceInfoService)
                
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

    // Mark: - readInterval
    func getValueForCharacteristic(characteristicID: CBUUID) -> NSData? {
        if let
            characteristic = findCharacteristicByID(characteristicID: characteristicID),
            let value = characteristic.value {
            return value as NSData
        }
        return nil
    }
    
    func didReadAdvertisingInterval() {
        let scannedSlot: NSNumber = NSNumber(value: currentlyScannedSlot)
        var advertisingInterval: UInt16 = 0
        if let value = getValueForCharacteristic(characteristicID: CharacteristicID.advertisingInterval.UUID) {
            value.getBytes(&advertisingInterval, length: MemoryLayout<UInt16>.size)
        }
        if slotData[scannedSlot] != nil {
            var littleEndianAdvInterval: UInt16 = CFSwapInt16BigToHost(advertisingInterval)
            let bytes = NSData(bytes: &littleEndianAdvInterval,
                               length: MemoryLayout<UInt16>.size)
            slotData[scannedSlot]![slotDataAdvIntervalKey] = bytes
            print("converted the slot data for advertising Interval \(bytes)")
            
        }else{
            print("the slotData[scannedSlot] is empty :( ")
            
        }
        //didUpdateInvestigationState(investigationState: InvestigationState.DidReadAdvertisingInterval)
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
                    print("The beacon is locked :( .")
                    didUpdateLockState(lockState: LockState.Locked)
                    unlockBeacon()
                } else {
                    print("The beacon is unlocked!")
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
