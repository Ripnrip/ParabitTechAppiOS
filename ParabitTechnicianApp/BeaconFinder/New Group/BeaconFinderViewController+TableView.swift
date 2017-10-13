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

extension BeaconFinderViewController: UITableViewDataSource, UITableViewDelegate {
    
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
        
        let currentBeacon = availableDoors[indexPath.row]
        if currentBeacon.isConnectable == true {
            //connect
            centralManager.connect(currentBeacon.sensorTag!, options: nil)
            SwiftSpinner.show(duration: 1.0, title: "Connecting", animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                let sensor = self.availableDoors[indexPath.row].sensorTag
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "BeaconTabBarController") as! BeaconTabBarController
                //TODO: Change tab bar controller's beacon to peripheral struct controller.currentBeacon = availableDoors[indexPath.row]
//                controller._eddystoneService = self.eddystoneService
//                controller._deviceInformationCharacteristic = self.deviceInformationCharacteristic
//                controller._advertisingIntervalCharacteristic = self.advertisingIntervalCharacteristic
//                controller._radioTxPowerCharacteristic = self.radioTxPowerCharacteristic
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

        if currentBeacon.isConnectable == true {
            cell.configurableStatusLabel.isHidden = false
            cell.statusBubbleImageView.backgroundColor = UIColor.green
        }
        else {
            cell.configurableStatusLabel.isHidden = true
        }

        cell.statusBubbleImageView.layer.cornerRadius = cell.statusBubbleImageView.frame.height/2
        cell.statusBubbleImageView.clipsToBounds = true
        return cell
    }
    
    
    
}
