//
//  GlobalSettingsViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/7/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import CoreBluetooth


class GlobalSettingsViewController: UIViewController {
    @IBOutlet weak var advLabel: UILabel!
    @IBOutlet weak var advSlider: UISlider!
    
    @IBOutlet weak var txPowerLabel: UILabel!

    var currentBeacon:Peripheral?
    
    var txPower:Int8 = 0
    var txPowerHex = "003"
    
    var advInterval:UInt16 = 1000
    var advIntervalHex = "03E8"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))

        guard let currentTabController = self.tabBarController as? BeaconTabBarController else { return }
        guard let beacon  = currentTabController.currentBeacon else { return }
        currentBeacon = beacon
        guard let txPowerValue = beacon.radioTxPowerCharacteristic else { return }
        guard let advSlotDataValue = beacon.advSlotDataCharacteristic else { return }
        guard let advertisingCharacteristic = beacon.advertisingIntervalCharacteristic else { return }
        
        let investigation = BeaconInvestigation(peripheral: (currentBeacon?.sensorTag!)!)
        txPower = investigation.didReadTxPower()
        txPowerLabel.text = "\(txPower) dBM"
        
        advInterval = beacon.advertisingValue ?? 0
        advLabel.text = "\(advInterval)"
        advSlider.value = Float(advInterval)
        
        print("the readPower data is \(investigation.didReadTxPower())")
        print("the readAdvertising data is \(investigation.didReadAdvertisingInterval())")

    }
    
    
    func saveTapped () {
        
        //Advertising Interval Save
        let adData = advIntervalHex.hexadecimal()
        currentBeacon?.sensorTag?.writeValue(adData!, for: (currentBeacon?.advertisingIntervalCharacteristic!)!, type: CBCharacteristicWriteType.withResponse)
        
        //TXPower Save
        let txData = txPowerHex.hexadecimal()
        currentBeacon?.sensorTag?.writeValue(txData!, for: (currentBeacon?.radioTxPowerCharacteristic!)!, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        let currentValue =   Float(slider.value).roundToHundreds()

        slider.value = Float(currentValue)
        advLabel.text = "\(currentValue)"
        
        switch currentValue {
        case 1000:
            advIntervalHex = "03E8"
        case 900:
            advIntervalHex = "0384"
        case 800:
            advIntervalHex = "0320"
        case 700:
            advIntervalHex = "02BC"
        case 600:
            advIntervalHex = "0258"
        case 500:
            advIntervalHex = "01F4"
        case 400:
            advIntervalHex = "0190"
        case 300:
            advIntervalHex = "012C"
        case 200:
            advIntervalHex = "0C8"
        case 100:
            advIntervalHex = "064"
        default:
            return
        }
        
    }
    
    @IBAction func stepperValueChanged(_ sender: Any) {
        guard let stepper = sender as? UIStepper else { return }
        
        switch stepper.value {
        case 0:
            txPower = -40
            txPowerHex = "d8"
        case 1:
            txPower = -20
            txPowerHex = "eC"
        case 2:
            txPower = -16
            txPowerHex = "f0"
        case 3:
            txPower = -12
            txPowerHex = "f4"
        case 4:
            txPower = -8
            txPowerHex = "f8"
        case 5:
            txPower = -4
            txPowerHex = "fc"
        case 6:
            txPower = 0
            txPowerHex = "00"
        case 7:
            txPower = 3
            txPowerHex = "03"
        case 8:
            txPower = 4
            txPowerHex = "04"
        default:
            txPower = 3
            txPowerHex = "d8"
        }
        txPowerLabel.text = "\(txPower) dBm"

    }
    

}

extension Float {
    func roundToHundreds() -> Int{
        return 100 * Int(Darwin.roundf(self / 100.0))
    }
}
