//
//  AvailableDoorsViewController+BlueTooth.swift
//  ParabitBeaconDemo
//
//  Created by Gurinder Singh on 10/3/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

extension AvailableDoorsViewController: CBCentralManagerDelegate, CBPeripheralDelegate {

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

                // save a reference to the sensor tag
                sensorTag = peripheral
                sensorTag.delegate = self
                
                //add peripheral to available doors tableview
                let paraDoor = Peripheral(name: peripheralName, UUID: peripheral.identifier.uuidString, isConnectable: true, sensorTag: sensorTag)
                availableDoors.append(paraDoor)
                doorsTableView.reloadData()
                
                //connect
                //centralManager.connect(sensorTag, options: nil)
            }
        }
    }

    /*
     Invoked when a connection is successfully created with a peripheral.
     
     This method is invoked when a call to connectPeripheral:options: is successful.
     You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    
    func centralManager(
        central: CBCentralManager,
        didConnectPeripheral peripheral: CBPeripheral) {
        print("did connect to device")
        
        peripheral.discoverServices(nil)
    }
    
    // Discover services of the peripheral

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!")

        let alert = UIAlertController(title: "Alert", message: "Successfully connected to the device", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)

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
        print("The discovered services are \(String(describing: peripheral.services))")
        print("The discovered characteristics are \(peripheral.services!.description)")

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
        doorsTableView.reloadData()

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
