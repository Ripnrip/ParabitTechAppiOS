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
        //connect
        SwiftSpinner.show(duration: 1.0, title: "Connecting", animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            let sensor = self.availableDoors[indexPath.row].sensorTag
            tableView.deselectRow(at: indexPath, animated: true)
        })

        return
        
        tableView.deselectRow(at: indexPath, animated: true)
        if beacons[indexPath.row].isConfigurable == true {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "BeaconTabBarController") as! BeaconTabBarController
            controller.currentBeacon = beacons[indexPath.row]
            self.navigationController?.pushViewController(controller, animated: true)
            
        }else{
            BPStatusBarAlert(duration: 0.5, delay: 0.5, position: .statusBar) // customize duration, delay and position
                .message(message: "Beacon not configurable")
                .messageColor(color: .white)
                .bgColor(color: .red)
                .completion { print("")}
                .show()
        }
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "beaconCell") as? ParaBeaconTableViewCell else {return UITableViewCell()}
        let currentBeacon = beacons[indexPath.row]
        //cell.addressLabel.text = currentBeacon.address
        //cell.nameSpaceLabel.text = currentBeacon.nameSpace
        //cell.instanceLabel.text = currentBeacon.instance
        
        if currentBeacon.isConfigurable == true {cell.configurableStatusLabel.isHidden = false}
        else {cell.configurableStatusLabel.isHidden = true}
        if currentBeacon.isRegistered == true {cell.registeredLabel.isHidden = false}
        else {cell.registeredLabel.isHidden = true}
        
        cell.statusBubbleImageView.layer.cornerRadius = cell.statusBubbleImageView.frame.height/2
        cell.statusBubbleImageView.clipsToBounds = true
        return cell
    }
    
    
    
}
