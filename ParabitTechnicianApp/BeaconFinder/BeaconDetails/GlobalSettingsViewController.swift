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
    @IBOutlet weak var advSlider: UISlider!
    
    @IBOutlet weak var txPowerLabel: UILabel!
    var txPower:Int8 = 0
    var advInterval:UInt16 = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let currentTabController = self.tabBarController as? BeaconTabBarController else { return }
        guard let beacon  = currentTabController.currentBeacon else { return }
        guard let txPowerValue = beacon.radioTxPowerCharacteristic else { return }
        guard let advSlotDataValue = beacon.advSlotDataCharacteristic else { return }
        guard let advertisingCharacteristic = beacon.advertisingIntervalCharacteristic else { return }
        
        let investigation = BeaconInvestigation(peripheral: beacon.sensorTag!)
        txPower = investigation.didReadTxPower()
        txPowerLabel.text = "\(txPower) dBM"
        
        advInterval = beacon.advertisingValue ?? 0
        advLabel.text = "\(advInterval)"
        advSlider.value = Float(advInterval)
        

        
        print("the readPower data is \(investigation.didReadTxPower())")
        print("the readAdvertising data is \(investigation.didReadAdvertisingInterval())")

        

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
