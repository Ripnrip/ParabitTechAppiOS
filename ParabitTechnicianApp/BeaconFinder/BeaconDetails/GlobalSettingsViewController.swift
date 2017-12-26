//
//  GlobalSettingsViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/7/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import CoreBluetooth
import Crashlytics
import AWSCognitoIdentityProvider

class GlobalSettingsViewController: UIViewController {
    @IBOutlet weak var generalFirmwareSegmentControl: UISegmentedControl!
    
    @IBOutlet weak var advLabel: UILabel!
    @IBOutlet weak var advSlider: UISlider!
    @IBOutlet weak var txPowerSlider: UISlider!
    
    @IBOutlet weak var txPowerLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    @IBOutlet weak var generalView: UIView!
    @IBOutlet weak var configurationView: UIView!
    @IBOutlet weak var updatesView: UIView!
    
    @IBOutlet weak var updatesButton: UIButton!
    @IBOutlet weak var updatesLabel: UILabel!
    
    //General Values
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var serialNumberLabel: UILabel!
    @IBOutlet weak var modelNumberLabel: UILabel!
    @IBOutlet weak var firwmareLabel: UILabel!
    @IBOutlet weak var hardwareLabel: UILabel!
    
    
    var isUpdateAvailable = false
    
    var currentBeacon:Peripheral?
    var currentFirmwareObject: FirmwareInfo?
    var firmwareZipURL : URL?
    
    var txPower:Int8 = 0
    var txPowerHex = "003"
    
    var advInterval:UInt16 = 1000
    var advIntervalHex = "03E8"
    
    var user:AWSCognitoIdentityUser?
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setup()
    }
    
    func setup(){
        let nc = NotificationCenter.default // Note that default is now a property, not a method call
        nc.addObserver(forName:Notification.Name(rawValue:"finishedDFU"),
                       object:nil, queue:nil,
                       using:catchNotification)
        
        let pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey )
        user = pool.currentUser()
        
        guard let currentTabController = self.tabBarController as? BeaconTabBarController else { return }
        guard let beacon  = currentTabController.currentBeacon else { return }
        currentBeacon = beacon
        nameLabel.text = beacon.deviceName
        serialNumberLabel.text = beacon.serialNumber
        modelNumberLabel.text = beacon.modelNumber
        firwmareLabel.text = beacon.firmwareRevision
        hardwareLabel.text = beacon.hardware

        guard let rssiValue = currentBeacon?.rssiValue else { return }
        rssiLabel.text = "\(rssiValue) db"
        
        let investigation = BeaconInvestigation(peripheral: (currentBeacon?.sensorTag!)!)
        txPower = investigation.didReadTxPower()
        txPowerLabel.text = "\(txPower) dBM"
        switch txPower{
        case -40:
            txPowerHex = "d8"
            txPowerSlider.value = 0
        case -20:
            txPowerSlider.value = 1
            txPowerHex = "eC"
        case -16:
            txPowerSlider.value = 2
            txPowerHex = "f0"
        case -12:
            txPowerSlider.value = 3
            txPowerHex = "f4"
        case -8:
            txPowerSlider.value = 4
            txPowerHex = "f8"
        case -4:
            txPowerSlider.value = 5
            txPowerHex = "fc"
        case 0:
            txPowerSlider.value = 6
            txPowerHex = "00"
        case 3:
            txPowerSlider.value = 7
            txPowerHex = "03"
        case 4:
            txPowerSlider.value = 8
            txPowerHex = "04"
        default:
            txPower = 3
            txPowerHex = "d8"
        }
        
        advInterval = beacon.advertisingValue ?? 0
        advLabel.text = "\(advInterval)"
        advSlider.value = Float(advInterval)
        
        print("the readPower data is \(investigation.didReadTxPower())")
        print("the readAdvertising data is \(investigation.didReadAdvertisingInterval())")
    }
    

    func catchNotification(notification:Notification) -> Void {
        print("Catch notification")
        
        guard let userInfo = notification.userInfo,
            let message  = userInfo["message"] as? String,
            let date     = userInfo["date"]    as? Date else {
                print("No userInfo found in notification")
                return
        }
        updatesButton.isHidden = true
        updatesLabel.text = "Firmware is up-to-date"
    }
    
    func saveTapped () {
        
        let alertController = UIAlertController(title: "Save Changes", message: "Are you sure you would like to save these new values?", preferredStyle: UIAlertControllerStyle.alert) //Replace UIAlertControllerStyle.Alert by UIAlertControllerStyle.alert
        
        let DestructiveAction = UIAlertAction(title: "No", style: UIAlertActionStyle.destructive) {
            (result : UIAlertAction) -> Void in
            print("No")
        }
        
        let okAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) {
            (result : UIAlertAction) -> Void in
            print("OK")
            //Advertising Interval Save
            let adData = self.advIntervalHex.hexadecimal()
            self.currentBeacon?.sensorTag?.writeValue(adData!, for: (self.currentBeacon?.advertisingIntervalCharacteristic!)!, type: CBCharacteristicWriteType.withResponse)
            
            //TXPower Save
            let txData = self.txPowerHex.hexadecimal()
            self.currentBeacon?.sensorTag?.writeValue(txData!, for: (self.currentBeacon?.radioTxPowerCharacteristic!)!, type: CBCharacteristicWriteType.withResponse)
            
            let alert = UIAlertController(title: "Success", message: "Saved new value(s)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        alertController.addAction(okAction)
        alertController.addAction(DestructiveAction)

        self.present(alertController, animated: true, completion: nil)
        
    }

    
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        let currentValue =   Float(slider.value).roundToHundreds()

        slider.value = Float(currentValue)
        advLabel.text = "\(currentValue)"
        
        guard let user = self.user else { return }
        Answers.logCustomEvent(withName: "USER_CHANGED_ADVERTISING_INTERVAL", customAttributes: ["user":user,"value":currentValue])
        
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
    
    @IBAction func txSliderChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        let currentValue =   Int(slider.value)
        
        guard let user = self.user else { return }
        Answers.logCustomEvent(withName: "USER_CHANGED_RADIO_TX_POWER_CHANGED", customAttributes: ["user":user,"value":currentValue])
        
        switch currentValue{//slider.value {
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
    
    @IBAction func toggleSwitched(_ sender: Any) {
        guard let toggle = sender as? UISegmentedControl else { return }
        
        switch toggle.selectedSegmentIndex {
        case 0:
            generalView.isHidden = false
            updatesView.isHidden = true
            configurationView.isHidden = true

        case 1:
            configurationView.isHidden = false
            updatesView.isHidden = true
            generalView.isHidden = true

        case 2:
            generalView.isHidden = true
            configurationView.isHidden = true
            updatesView.isHidden = false
            checkForUpdates(self)
        default:
            return
        }
    }
    
    @IBAction func checkForUpdates(_ sender: Any) {
        guard let user = self.user else { return }
        Answers.logCustomEvent(withName: "USER_CHECKED_FOR_FIRWARE_UPDATES", customAttributes: ["user":user])
        
        if isUpdateAvailable == false {
            //test networking call valid -> 01-10-17 --
            guard let revisionString = currentBeacon?.firmwareRevision else { return }
            ParabitNetworking.sharedInstance.getFirmwareInfoFor(revision: revisionString) { (firmware) in
                if firmware != nil {
                    print("got the revision firmware")
                    Answers.logCustomEvent(withName: "FIRMWARE_UPDATE_FOUND", customAttributes: ["user":user,"version":firmware?.latestFirmware.id ?? 0])
                    self.currentFirmwareObject = firmware
 
                    DispatchQueue.global(qos: .userInitiated).async {
                        //download currentFirmware.latestURL and use the zip for the next vc

                        guard let downloadURL = self.currentFirmwareObject?.latestURL else { return }
                        // create your document folder url
                        let documentsUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                        // your destination file url
                        let destination = documentsUrl.appendingPathComponent(downloadURL.lastPathComponent)
                        print(destination)
                        // check if it exists before downloading it
                        if FileManager().fileExists(atPath: destination.path) {
                            //file exists, set the firmware file URL to that path
                            print("The file already exists at path")
                            DispatchQueue.main.async {
                                self.firmwareZipURL = destination
                                self.updatesLabel.text = "Update found"
                                self.updatesButton.setTitle("Update firmware", for: .normal)
                                self.isUpdateAvailable = true
                            }
                        } else {
                            //  if the file doesn't exist
                            //  just download the data from your url
                            URLSession.shared.downloadTask(with: downloadURL, completionHandler: { (location, response, error) in
                                // after downloading your data you need to save it to your destination url
                                guard
                                    let httpURLResponse = response as? HTTPURLResponse,
                                    let location = location, error == nil
                                    else { return }
                                do {
                                    try FileManager.default.moveItem(at: location, to: destination)
                                    print("file saved")
                                    DispatchQueue.main.async {
                                        self.updatesLabel.text = "Update found"
                                        self.updatesButton.setTitle("Update firmware", for: .normal)
                                        self.isUpdateAvailable = true
                                        self.firmwareZipURL = destination
                                    }
                                    
                                } catch {
                                    print(error)
                                }
                            }).resume()
                        }
                    }
                    
                }else{
                    print("error getting firmware info for revison, or the firmware is up-to-date")
                    guard let user = self.user else { return }
                    Answers.logCustomEvent(withName: "ERROR_WITH_RETRIEVING_REVISION", customAttributes: ["user":user,"firmware":firmware.debugDescription ?? ""])
                    
                    DispatchQueue.main.async {
                        self.updatesLabel.text = "Firmware is up-to-date"
                    }
                }
            }
        } else {
            //go to update screen
            //self.performSegue(withIdentifier: "showDFU", sender: nil)
            
            guard let user = self.user else { return }
            Answers.logCustomEvent(withName: "USER_WENT_TO_START_DFU", customAttributes: ["user":user])
            
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let dfuViewController = storyboard.instantiateViewController(withIdentifier :"dfuViewController") as? DFUViewController, let myTabBarController = self.tabBarController as? BeaconTabBarController, let centralManager = myTabBarController.centralManager, let selectedPeripheral = myTabBarController.selectedPeripheral else { return }
            
            dfuViewController.setCentralManager(centralManager)
            dfuViewController.secureDFUMode(myTabBarController.selectedPeripheralIsSecure)
            dfuViewController.setTargetPeripheral(selectedPeripheral)
            guard let zipURL = self.firmwareZipURL else { return }
            dfuViewController.setSelectedFileURL(zipURL)
            
            //self.present(dfuViewController, animated: true)
            self.navigationController?.pushViewController(dfuViewController, animated: true)
            
        }
    }

}

extension Float {
    func roundToHundreds() -> Int{
        return 100 * Int(Darwin.roundf(self / 100.0))
    }
}
