//
//  BeaconFinderViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/5/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import SwiftSpinner
import BPStatusBarAlert
import CoreBluetooth
 
class BeaconFinderViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var beacons = [Parabeacon]()
    var currentBeacon:Peripheral?
    var centralManager:CBCentralManager!
    var sensorTag:CBPeripheral!
    var keepScanning:Bool = true
    // define our scanning interval times
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0
    
    var availableDoors = [Peripheral]()
    var slotData: Dictionary <NSNumber, Dictionary <String, NSData>> = [:]
    var slotUpdateData: Dictionary <NSNumber, Dictionary <String, NSData>> = [:]
    var beaconCapabilities: NSDictionary = [:]

    let peripheralName = "Parabeacon"
    let eddystoneConfigurationServiceUUID = "A3C87500-8ED3-4BDF-8A39-A01BEBEDE295"
    let deviceInformationServiceUUID = "0000180a-0000-1000-8000-00805f9b34fb"
    let advertisingInterval = "A3C87503-8ED3-4BDF-8A39-A01BEBEDE295"
    let radioTxPower = "A3C87504-8ED3-4BDF-8A39-A01BEBEDE295"
    
    var eddystoneService: CBService?
    var deviceInformationCharacteristic: CBCharacteristic?
    var advertisingIntervalCharacteristic: CBCharacteristic?
    var radioTxPowerCharacteristic: CBCharacteristic?
    
    var beaconPasskey: String?
    var beaconInvestigation: BeaconInvestigation?
    var userPasskey: String? = "BD3690EC52B779A30344A52A84D00AD9"
    var didAttemptUnlocking = false
    var beaconGATTOperations: GATTOperations?
    var beaconOperationsCallback: ((_ operationState: OperationState) -> Void)?
    var lockStateCallback: ((_ lockState: LockState) -> Void)?
    var updateLockStateCallback: ((_ lockState: LockState) -> Void)?
    var remainConnectableCallback: (() -> Void)?
    var factoryResetCallback: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorColor = UIColor.clear
        self.title = "Parabit Beacon Config"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = UIColor.orange
        
        loadBeacons()
        self.tableView.separatorColor = UIColor.clear
        
        centralManager = CBCentralManager(delegate: self,
                                          queue: nil)
        
    }

    func loadBeacons(){
        let beacon1 = Parabeacon(name: "Parabeacon", description: nil, address: "EC:A9:AB:10:DE:68", nameSpace: "E9C5284C7DF143AF97C2", instance: "5051CB3FA58B", rssi: -39, isConfigurable: false, slotsAvailable: 1, eidSlotsAvailable: 1, advInterval: nil, isRegistered: false)
        beacons.append(beacon1)
        tableView.reloadData()
    }

    @IBAction func refresh(_ sender: Any) {
        SwiftSpinner.show("Scanning")

        let when = DispatchTime.now() + 0 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
                self.availableDoors = []
                self.centralManager.scanForPeripherals(withServices: nil, options: nil)
                self.tableView.reloadData()
        }
        
    }
    
    func investigateBeacon() {
        if let connectedBeacon = sensorTag {
            self.beaconInvestigation = BeaconInvestigation(peripheral: connectedBeacon)
            if let investigation = self.beaconInvestigation {
                investigation.finishedUnlockingBeacon() { beaconCapabilities, slotData in
                    /// Creates the buttons and the pages for them and populate them with the information.
                    DispatchQueue.main.async {
                        //self.beaconConnectionView.isHidden = true
                        //self.dismiss(animated: false, completion: nil)
                        self.slotData = slotData
                        self.beaconCapabilities = beaconCapabilities
                        if let beaconDataSlotsCount = beaconCapabilities[maxSupportedSlotsKey] as? NSNumber {
                           // self.createContentViews(beaconDataSlotsCount: beaconDataSlotsCount as Int)
                            //self.displayScrollBar(beaconSlotDataCount: beaconDataSlotsCount as Int)
                            //self.saveButton.isEnabled = true
                        }
                    }
                }
            }
        }
    }
    
}
