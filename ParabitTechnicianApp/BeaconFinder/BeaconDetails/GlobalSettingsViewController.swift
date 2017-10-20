//
//  GlobalSettingsViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/7/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit

class GlobalSettingsViewController: UIViewController {
    @IBOutlet weak var advLabel: UILabel!
    
    @IBOutlet weak var txPowerLabel: UILabel!
    var txPower = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //txPower Value
        guard let currentTabController = self.tabBarController as? BeaconTabBarController else { return }
        guard let beacon  = currentTabController.currentBeacon else { return }
        guard let txPowerValue = beacon.radioTxPowerCharacteristic?.value else { return }
        guard let advSlotDataValue = beacon.advSlotDataCharacteristic else { return }
        
        let investigation = BeaconInvestigation(peripheral: beacon.sensorTag!)
        print("the readPower data is \(investigation.didReadTxPower())")
        print("the readAdvertising data is \(investigation.didReadAdvertisingInterval())")
        

        print(" the advSlotData is \(advSlotDataValue) and the txPower Value is \(txPowerValue))")
        

    }
    
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        let currentValue =   Float(slider.value).roundToHundreds()

        slider.value = Float(currentValue)
        advLabel.text = "\(currentValue)"
    }
    
    @IBAction func stepperValueChanged(_ sender: Any) {
        guard let stepper = sender as? UIStepper else { return }
        
        switch stepper.value {
        case 0:
            txPower = -40
        case 1:
            txPower = -20
        case 2:
            txPower = -16
        case 3:
            txPower = -12
        case 4:
            txPower = -8
        case 5:
            txPower = -4
        case 6:
            txPower = 0
        case 7:
            txPower = 3
        case 8:
            txPower = 4
        default:
            txPower = 3
        }
        txPowerLabel.text = "\(txPower) dBm"

    }
    

}

extension Float {
    func roundToHundreds() -> Int{
        return 100 * Int(Darwin.roundf(self / 100.0))
    }
}
