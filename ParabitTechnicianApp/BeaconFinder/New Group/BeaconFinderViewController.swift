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
    var callback: ((_ beaconBroadcastCapabilities: NSDictionary,
    _ slotData: Dictionary <NSNumber, Dictionary <String, NSData>>) -> Void)?
    var beaconCapabilities: NSDictionary = [:]
    var currentlyScannedSlot: UInt8 = 0


    let peripheralName = "Parabeacon"
    let eddystoneConfigurationServiceUUID = "A3C87500-8ED3-4BDF-8A39-A01BEBEDE295"
    let deviceInformationServiceUUID = "180A"
    let advertisingInterval = "A3C87503-8ED3-4BDF-8A39-A01BEBEDE295"
    let radioTxPower = "A3C87504-8ED3-4BDF-8A39-A01BEBEDE295"
    let unlockUUID = "A3C87507-8ED3-4BDF-8A39-A01BEBEDE295"
    let advSlotData = "A3C8750A-8ED3-4BDF-8A39-A01BEBEDE295"
    
    var eddystoneService: CBService?
    var deviceInformationService: CBService?
    
    var isBeaconUnlocked = false
    
    var beaconPasskey: String?
    var beaconInvestigation: BeaconInvestigation?
    var userPasskey: String? = "BD3690EC52B779A30344A52A84D00AD9"//"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
    var didAttemptUnlocking = false
    var beaconGATTOperations: GATTOperations?
    var beaconOperationsCallback: ((_ operationState: OperationState) -> Void)?
    var lockStateCallback: ((_ lockState: LockState) -> Void)?
    var updateLockStateCallback: ((_ lockState: LockState) -> Void)?
    var remainConnectableCallback: (() -> Void)?
    var factoryResetCallback: (() -> Void)?

    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorColor = UIColor.clear
        self.title = "Parabit Beacon Config"
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = UIColor.orange
        
        self.tableView.separatorColor = UIColor.clear
        
        centralManager = CBCentralManager(delegate: self,
                                          queue: nil)
        
    }

    @IBAction func refresh(_ sender: Any) {
        SwiftSpinner.show(duration: 4, title: "Scanning")

        let when = DispatchTime.now() + 0 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
                self.availableDoors = []
                self.centralManager.scanForPeripherals(withServices: nil, options: nil)
                self.tableView.reloadData()
        }
    }

    
}
