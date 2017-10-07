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

extension BeaconFinderViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beacons.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        if beacons[indexPath.row].isConfigurable == true {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "BeaconTabBarController") as! BeaconTabBarController
            controller.currentBeacon = beacons[indexPath.row]
            self.navigationController?.pushViewController(controller, animated: true)
            
        }else{
            BPStatusBarAlert(duration: 0.5, delay: 0.5, position: .statusBar) // customize duration, delay and position
                .message(message: "Beacon not configurable")         // customize message
                .messageColor(color: .white)                                // customize message color
                .bgColor(color: .red)                                      // customize view's background color
                .completion { print("")}
                .show()                                                     // Animation start
        }
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "beaconCell") as? ParaBeaconTableViewCell else {return UITableViewCell()}
        let currentBeacon = beacons[indexPath.row]
        cell.addressLabel.text = currentBeacon.address
        cell.nameSpaceLabel.text = currentBeacon.nameSpace
        cell.instanceLabel.text = currentBeacon.instance
        
        if currentBeacon.isConfigurable == true {cell.configurableStatusLabel.isHidden = false}
        else {cell.configurableStatusLabel.isHidden = true}
        if currentBeacon.isRegistered == true {cell.registeredLabel.isHidden = false}
        else {cell.registeredLabel.isHidden = true}
        
        cell.statusBubbleImageView.layer.cornerRadius = cell.statusBubbleImageView.frame.height/2
        cell.statusBubbleImageView.clipsToBounds = true
        return cell
    }
    
    
    
}
