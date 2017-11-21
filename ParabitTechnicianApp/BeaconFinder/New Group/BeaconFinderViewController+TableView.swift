//
//  BeaconFinderViewController+TableView.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/5/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import UIKit
import BPStatusBarAlert
import SwiftSpinner

extension BeaconFinderViewController: UITableViewDelegate, UITableViewDataSource{
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableDoors.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let currentBeacon = self.availableDoors[indexPath.row]
        if currentBeacon.isConnectable == true && currentBeacon.name == peripheralName && beaconInvestigation?.discoveredAdvAndTXCharacteristic == true {
            //connect
            //centralManager.connect(currentBeacon.sensorTag!, options: nil)
            SwiftSpinner.show(duration: 3.0, title: "Connecting", animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                let sensor = self.availableDoors[indexPath.row].sensorTag
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "BeaconTabBarController") as! BeaconTabBarController
                //TODO: Change tab bar controller's beacon to peripheral struct controller.currentBeacon = availableDoors[indexPath.row]
                controller.currentBeacon = self.currentBeacon
                controller.eddystoneService = self.eddystoneService
                controller.centralManager = self.centralManager
                controller.selectedPeripheral = self.sensorTag
                controller.selectedPeripheralIsSecure = true 
                

                self.navigationController?.pushViewController(controller, animated: true)
            })
        }else{
            //if non-connectable, alert user
            BPStatusBarAlert(duration: 0.5, delay: 0.5, position: .statusBar) // customize duration, delay and position
                .message(message: "Beacon not configurable")
                .messageColor(color: .white)
                .bgColor(color: .red)
                .completion { print("")}
                .show()
        }
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "beaconCell") as? ParaBeaconTableViewCell else {return UITableViewCell()}
        let currentBeacon = availableDoors[indexPath.row]
        
        cell.beaconNameLabel.text = currentBeacon.name
        cell.disconnectButton.addTarget(self, action: #selector(BeaconFinderViewController.disconnectTapped(_:)), for: .touchUpInside)

        if currentBeacon.isConnectable == true  {
            cell.configurableStatusLabel.isHidden = false
            cell.disconnectButton.isHidden = false
            cell.statusBubbleImageView.backgroundColor = UIColor.green
        }
        else {
            cell.configurableStatusLabel.isHidden = true
            cell.disconnectButton.isHidden = true
            cell.statusBubbleImageView.backgroundColor = UIColor.red

        }
        
        cell.statusBubbleImageView.layer.cornerRadius = cell.statusBubbleImageView.frame.height/2
        cell.statusBubbleImageView.clipsToBounds = true
        
        guard let rssiValue = currentBeacon.rssiValue else {return UITableViewCell()}
        cell.rssiLabel.text = "RSSI: \(rssiValue)"
        
        return cell
    }
    
    func disconnectTapped(_ sender: Any?) {
        print("disconnectTapped", sender)
        guard let sensor = sensorTag else { return }
        self.centralManager.cancelPeripheralConnection(sensor)
        self.refresh(self)
    }
    
    
}
