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

class BeaconFinderViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var beacons = [Parabeacon]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorColor = UIColor.clear
        self.title = "Parabit Beacon Config"
        loadBeacons()
        
    }

    func loadBeacons(){
        let beacon1 = Parabeacon(name: "Parabeacon", description: nil, address: "EC:A9:AB:10:DE:68", nameSpace: "E9C5284C7DF143AF97C2", instance: "5051CB3FA58B", rssi: -39, isConfigurable: false, slotsAvailable: 1, eidSlotsAvailable: 1, advInterval: nil, isRegistered: false)
        beacons.append(beacon1)
        tableView.reloadData()
    }

    @IBAction func refresh(_ sender: Any) {
        SwiftSpinner.show(duration: 1.5, title: "Scanning", animated: true)
        
        let when = DispatchTime.now() + 2 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            // Your code with delay
            BPStatusBarAlert(duration: 0.5, delay: 0.5, position: .statusBar) // customize duration, delay and position
                .message(message: "Found 1 beacon")         // customize message
                .messageColor(color: .white)                                // customize message color
                .bgColor(color: .blue)                                      // customize view's background color
                .completion { print("completion closure will called")}
                .show()                                                     // Animation start
            
                self.beacons.forEach { (beacon) in
                    beacon.isConfigurable = true
                }
                self.tableView.reloadData()
        }


        
        
    }
}
