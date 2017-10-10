//
//  AvailableDoorsViewController.swift
//  ParabitBeaconDemo
//
//  Created by Gurinder Singh on 10/2/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import CoreBluetooth
class AvailableDoorsViewController: UIViewController {

    @IBOutlet weak var doorsTableView: UITableView!
    
    var centralManager:CBCentralManager!
    var sensorTag:CBPeripheral!
    var keepScanning:Bool = true
    // define our scanning interval times
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0

    var availableDoors = [Peripheral]()
    
    static let sensorTagName = "Parabeacon"
    static let preUUID = "C9D53F67-F276-B37C-FAAF-040558BDEC4B"
    static let postUUID = "A3C87500-8ED3-4BDF-8A39-A01BEBEDE295"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.doorsTableView.separatorColor = UIColor.clear

        centralManager = CBCentralManager(delegate: self,
                                          queue: nil)
        
    }


}
