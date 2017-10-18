//
//  BeaconTabBarController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/7/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import CoreBluetooth

class BeaconTabBarController: UITabBarController {
    
    var currentBeacon:Peripheral?
    var eddystoneService: CBService?
    var deviceInformationCharacteristic: CBCharacteristic?
    var advertisingIntervalCharacteristic: CBCharacteristic?
    var radioTxPowerCharacteristic: CBCharacteristic?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let btn1 = UIButton(type: .custom)
        btn1.setImage(UIImage(named: "more"), for: .normal)
        btn1.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        //btn1.addTarget(self, action: #selector(Class.Methodname), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: btn1)
        
        let btn2 = UIButton(type: .custom)
        btn2.setImage(UIImage(named: "save"), for: .normal)
        btn2.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        //btn2.addTarget(self, action: #selector(Class.MethodName), for: .touchUpInside)
        let item2 = UIBarButtonItem(customView: btn2)
        
        self.navigationItem.setRightBarButtonItems([item1,item2], animated: true)
        
        guard let beacon = currentBeacon else { return }
        
        //guard let advertisingCharacteristic = advertisingIntervalCharacteristic else { return }
        //beacon.sensorTag?.readValue(for: advertisingCharacteristic)
        //beacon.sensorTag?.readValue(for: radioTxPowerCharacteristic!)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
