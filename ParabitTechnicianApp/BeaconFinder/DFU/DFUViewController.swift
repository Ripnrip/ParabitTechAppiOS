//
//  DFUViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/7/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import CoreBluetooth
import iOSDFULibrary
import Crashlytics
import AWSCognitoIdentityProvider

class DFUViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, DFUServiceDelegate, DFUProgressDelegate, LoggerDelegate {
    
    static let ExperimentalButtonlessDfuUUID = CBUUID(string: "4390e0ec-e218-80b1-f34f-13a3f6fcb819")
    static var legacyDfuServiceUUID  = CBUUID(string: "C9D53F67-F276-B37C-FAAF-040558BDEC4B")
    static var secureDfuServiceUUID  = CBUUID(string: "FE59")
    static var deviceInfoServiceUUID = CBUUID(string: "180A")
    
    //MARK: - DFU File URL
    
    
    //MARK: - Class Properties
    fileprivate var dfuPeripheral    : CBPeripheral?
    fileprivate var dfuController    : DFUServiceController?
    fileprivate var centralManager   : CBCentralManager?
    fileprivate var selectedFirmware : DFUFirmware?
    fileprivate var selectedFileURL  : URL?
    fileprivate var secureDFU        : Bool?
    
    //MARK: - View Outlets
    @IBOutlet weak var dfuView: UIView!
    @IBOutlet weak var dfuActivityIndicator  : UIActivityIndicatorView!
    @IBOutlet weak var dfuStatusLabel        : UILabel!
    @IBOutlet weak var peripheralNameLabel   : UILabel!
    @IBOutlet weak var dfuUploadProgressView : UIProgressView!
    @IBOutlet weak var dfuUploadStatus       : UILabel!
    @IBOutlet weak var stopProcessButton     : UIButton!
    
    var user: AWSCognitoIdentityUser?
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.navigationItem.rightBarButtonItem = nil
        
        let pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        user = pool.currentUser()
        
        guard let myTabBarController = self.tabBarController as? BeaconTabBarController else { return }
        self.dfuPeripheral = myTabBarController.selectedPeripheral
        self.centralManager = myTabBarController.centralManager
        self.secureDFU = myTabBarController.selectedPeripheralIsSecure
        

        peripheralNameLabel.text = "Flashing \((dfuPeripheral?.name)!)..."
        dfuActivityIndicator.startAnimating()
        dfuUploadProgressView.progress = 0.0
        dfuUploadStatus.text = ""
        dfuStatusLabel.text  = ""
        stopProcessButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if selectedFileURL != nil {
           // let url = Bundle.main.url(forResource: "pb_secure_dfu_package", withExtension: "zip")!
            //selectedFirmware = DFUFirmware(urlToZipFile: url)
            selectedFirmware = DFUFirmware(urlToZipFile: selectedFileURL!)
            startDFUProcess()
        } else {
            centralManager!.delegate = self
            centralManager!.connect(dfuPeripheral!)
        }
        

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _ = dfuController?.abort()
        dfuController = nil
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    //MARK: - View Actions
    @IBAction func stopProcessButtonTapped(_ sender: AnyObject) {
        guard dfuController != nil else {
            print("No DFU peripheral was set")
            return
        }
        guard !dfuController!.aborted else {
            stopProcessButton.setTitle("Stop process", for: .normal)
            dfuController!.restart()
            return
        }
        
        print("Action: DFU paused")
        dfuController!.pause()
        let alertView = UIAlertController(title: "Warning", message: "Are you sure you want to stop the process?", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Abort", style: .destructive) {
            (action) in
            print("Action: DFU aborted")
            _ = self.dfuController!.abort()
        })
        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel) {
            (action) in
            print("Action: DFU resumed")
            self.dfuController!.resume()
        })
        present(alertView, animated: true)
    }
    
    //MARK: - Class Implementation
    func secureDFUMode(_ secureDFU: Bool?) {
        self.secureDFU = secureDFU
    }
    
    func setCentralManager(_ centralManager: CBCentralManager) {
        self.centralManager = centralManager
    }
    
    func setTargetPeripheral(_ targetPeripheral: CBPeripheral) {
        self.dfuPeripheral = targetPeripheral
    }
    
    func setSelectedFileURL (_ url:URL) {
        self.selectedFileURL = url
    }
    
    func getBundledFirmwareURLHelper() -> URL? {
        if let secureDFU = secureDFU {
            if secureDFU {
                return Bundle.main.url(forResource: "pb_secure_dfu_package", withExtension: "zip")!
            } else {
                return Bundle.main.url(forResource: "hrm_legacy_dfu_with_sd_s132_2_0_0", withExtension: "zip")!
            }
        } else {
            // We need to connect and discover services. The device does not have to advertise with the service UUID.
            return nil
        }
    }
    //pb_secure_dfu_package
    func startDFUProcess() {
        
        guard let user = self.user else { return }
        Answers.logCustomEvent(withName: "USER_STARTED_DFU", customAttributes: ["user":user,"firmware":selectedFirmware.debugDescription])
        
        
        guard dfuPeripheral != nil else {
            print("No DFU peripheral was set")
            return
        }
        
        let dfuInitiator = DFUServiceInitiator(centralManager: centralManager!, target: dfuPeripheral!)
        dfuInitiator.delegate = self
        dfuInitiator.progressDelegate = self
        dfuInitiator.logger = self
        
        // This enables the experimental Buttonless DFU feature from SDK 12.
        // Please, read the field documentation before use.
        dfuInitiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        guard let firmware = selectedFirmware else { return }
        dfuController = dfuInitiator.with(firmware: firmware).start()
    }
    
    //MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("CM did update state: \(central.state.rawValue)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let name = peripheral.name ?? "Unknown"
        print("Connected to peripheral: \(name)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let name = peripheral.name ?? "Unknown"
        print("Disconnected from peripheral: \(name)")
    }
    
    //MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // Find DFU Service
        let services = peripheral.services!
        for service in services {
            if service.uuid.isEqual(DFUViewController.legacyDfuServiceUUID) {
                secureDFU = false
                break
            } else if service.uuid.isEqual(DFUViewController.secureDfuServiceUUID) {
                secureDFU = true
                break
            } else if service.uuid.isEqual(DFUViewController.ExperimentalButtonlessDfuUUID) {
                secureDFU = true
                break
            }
        }
        if secureDFU != nil {
            selectedFirmware = DFUFirmware(urlToZipFile: selectedFileURL!)
            startDFUProcess()
        } else {
            print("Disconnecting...")
            centralManager?.cancelPeripheralConnection(peripheral)
            dfuError(DFUError.deviceNotSupported, didOccurWithMessage: "Device not supported")
        }
    }

    //MARK: - DFUServiceDelegate
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .completed, .disconnecting:
            self.dfuActivityIndicator.stopAnimating()
            self.dfuUploadProgressView.setProgress(0, animated: true)
            self.stopProcessButton.isEnabled = false
        case .aborted:
            self.dfuActivityIndicator.stopAnimating()
            self.dfuUploadProgressView.setProgress(0, animated: true)
            self.stopProcessButton.setTitle("Restart", for: .normal)
            self.stopProcessButton.isEnabled = true
        default:
            self.stopProcessButton.isEnabled = true
        }
        
        dfuStatusLabel.text = state.description()
        print("Changed state to: \(state.description())")
        
        // Forget the controller when DFU is done
        if state == .completed {
            guard let user = self.user else { return }
            Answers.logCustomEvent(withName: "USER_FINISHED_DFU", customAttributes: ["user":user,"firmware":selectedFirmware.debugDescription])
            
            dfuController = nil
            
            //notify listeners
            let nc = NotificationCenter.default
            nc.post(name:Notification.Name(rawValue:"finishedDFU"),
                    object: nil,
                    userInfo: ["message":"Hello there!", "date":Date()])
        }
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        dfuStatusLabel.text = "Error \(error.rawValue): \(message)"
        dfuActivityIndicator.stopAnimating()
        dfuUploadProgressView.setProgress(0, animated: true)
        print("Error \(error.rawValue): \(message)")
        
        guard let user = self.user else { return }
        Answers.logCustomEvent(withName: "ERROR_WITH_DFU", customAttributes: ["user":user,"firmware":selectedFirmware.debugDescription,"error":message])
        
        // Forget the controller when DFU finished with an error
        dfuController = nil
    }
    
    //MARK: - DFUProgressDelegate
    
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        dfuUploadProgressView.setProgress(Float(progress)/100.0, animated: true)
        dfuUploadStatus.text = String(format: "Part: %d/%d\nSpeed: %.1f KB/s\nAverage Speed: %.1f KB/s",
                                      part, totalParts, currentSpeedBytesPerSecond/1024, avgSpeedBytesPerSecond/1024)
    }
    
    //MARK: - LoggerDelegate
    
    func logWith(_ level: LogLevel, message: String) {
        print("\(level.name()): \(message)")
    }
    
    
    
    


}
