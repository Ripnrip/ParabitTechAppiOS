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
import Crashlytics

extension BeaconFinderViewController: UITableViewDelegate, UITableViewDataSource{
    

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Connectable"
        case 1:
            return "Advertising"
        default:
            return ""
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return availableDoors.filter { $0.isConnectable }.count
        case 1:
            return availableDoors.filter { !$0.isConnectable }.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            //if non-connectable, alert user
            guard let user = self.user else { return }
            EventsLogger.sharedInstance.logEvent(event: Events.User.USER_TAPPED_NONCONNECTABLE_BEACON, info: ["user":user])

            BPStatusBarAlert(duration: 0.5, delay: 0.5, position: .statusBar) // customize duration, delay and position
                .message(message: "This beacon is not connectable")
                .messageColor(color: .white)
                .bgColor(color: .red)
                .completion { print("")}
                .show()
            
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
            
        let currentBeacon = self.availableDoors[indexPath.row]

        if currentBeacon.isConnectable == true && currentBeacon.name == peripheralName   {
            //set isUnlocked to true
            //self.availableDoors[indexPath.row].isUnlocked = true
            
            //connect
            //connectTapped(self)
            guard let user = self.user, let sensor = sensorTag else { return }
            EventsLogger.sharedInstance.logEvent(event: Events.User.USER_TAPPED_CONNECT, info: ["user":user,"beacon":currentBeacon])

            centralManager.connect(sensor, options: nil)
            
            SwiftSpinner.show(duration: 5.1, title: "Connecting", animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.8, execute: {
                let sensor = self.availableDoors[indexPath.row].sensorTag
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "BeaconTabBarController") as! BeaconTabBarController
                controller.currentBeacon = self.currentBeacon
                controller.eddystoneService = self.eddystoneService
                controller.centralManager = self.centralManager
                controller.selectedPeripheral = self.sensorTag
                controller.selectedPeripheralIsSecure = true
                
                guard let user = self.user else { return }
                EventsLogger.sharedInstance.logEvent(event: Events.User.USER_OPENED_BEACON_CONFIGURATION, info: ["user":user])

                self.navigationController?.pushViewController(controller, animated: true)
            })
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "beaconCell") as? ParaBeaconTableViewCell else { return UITableViewCell() }
        let currentBeacon = availableDoors[indexPath.row]
        
        cell.beaconNameLabel.text = currentBeacon.name
        
        cell.connectButton.addTarget(self, action: #selector(BeaconFinderViewController.connectTapped(_:)), for: .touchUpInside)
        cell.disconnectButton.addTarget(self, action: #selector(BeaconFinderViewController.disconnectTapped(_:)), for: .touchUpInside)

        if indexPath.section == 0 {
            cell.configurableStatusLabel.isHidden = false
            //cell.disconnectButton.isHidden = true
            cell.connectButton.isHidden = false
            cell.statusBubbleImageView.backgroundColor = UIColor.green
            
        } else if indexPath.section == 1 {
            cell.configurableStatusLabel.isHidden = true
            cell.disconnectButton.isHidden = true
            cell.connectButton.isHidden = true
            cell.statusBubbleImageView.backgroundColor = UIColor.red
        }
        
        if currentBeacon.isUnlocked == true && indexPath.section != 1 {
            cell.disconnectButton.isHidden = false
            cell.connectButton.isHidden = true
        } else {
            cell.disconnectButton.isHidden = true
        }
        
        cell.statusBubbleImageView.layer.cornerRadius = cell.statusBubbleImageView.frame.height/2
        cell.statusBubbleImageView.clipsToBounds = true
        
        guard let rssiValue = currentBeacon.rssiValue else { return UITableViewCell() }
        cell.rssiLabel.text = "RSSI: \(rssiValue)"
        
        return cell
    }
    
    func disconnectTapped(_ sender: Any?) {
        print("disconnectTapped", sender)
        guard let user = self.user, let sensor = sensorTag else { return }
        EventsLogger.sharedInstance.logEvent(event: Events.User.USER_TAPPED_DISCONNECT, info: ["user":user])

        self.centralManager.cancelPeripheralConnection(sensor)
        self.refresh(self)
    }
    
    func connectTapped(_ sender: Any?) {
        
//        SwiftSpinner.show(delay: 4.0, title: "Connecting")
//        print("connectTapped", sender)
//        guard let user = self.user else { return }
//        Answers.logCustomEvent(withName: "USER_TAPPED_CONNECT", customAttributes: ["user":user])
//        guard let sensor = sensorTag else { return }
//        centralManager.connect(sensor, options: nil)
        
       // SwiftSpinner.show("Connecting", animated: true)
        
    }
    
    
}
