//
//  AvailableDoorsViewController+TableView.swift
//  ParabitBeaconDemo
//
//  Created by Gurinder Singh on 10/2/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import UIKit

extension AvailableDoorsViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableDoors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "doorCell") else {return UITableViewCell()}
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 128
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sensor = availableDoors[indexPath.row].sensorTag
        centralManager.connect(sensor, options: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
