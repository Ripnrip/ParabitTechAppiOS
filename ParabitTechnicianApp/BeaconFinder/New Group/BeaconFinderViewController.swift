//
//  BeaconFinderViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/5/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import SwiftSpinner
import BPStatusBarAlert
import CoreBluetooth
import AWSCognitoIdentityProvider
import Crashlytics

class BeaconFinderViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var emailLabel: UILabel!
    
    var beacons = [Parabeacon]()
    var currentBeacon:Peripheral?
    var centralManager:CBCentralManager!
    var sensorTag:CBPeripheral!
    var keepScanning:Bool = true
    // define our scanning interval times
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0
    
    var availableDoors = [Peripheral]()
    var slotData: Dictionary <NSNumber, Dictionary <String, NSData>> = [:]
    var callback: ((_ beaconBroadcastCapabilities: NSDictionary,
    _ slotData: Dictionary <NSNumber, Dictionary <String, NSData>>) -> Void)?
    var beaconCapabilities: NSDictionary = [:]
    var currentlyScannedSlot: UInt8 = 0


    let peripheralName = "Parabeacon"
    let eddystoneConfigurationServiceUUID = "A3C87500-8ED3-4BDF-8A39-A01BEBEDE295"
    let deviceInformationServiceUUID = "180A"
    let advertisingInterval = "A3C87503-8ED3-4BDF-8A39-A01BEBEDE295"
    let radioTxPower = "A3C87504-8ED3-4BDF-8A39-A01BEBEDE295"
    let unlockUUID = "A3C87507-8ED3-4BDF-8A39-A01BEBEDE295"
    let advSlotData = "A3C8750A-8ED3-4BDF-8A39-A01BEBEDE295"
    
    var eddystoneService: CBService?
    var deviceInformationService: CBService?
    
    var isBeaconUnlocked = false
    
    var beaconPasskey: String?
    var beaconInvestigation: BeaconInvestigation?
    var userPasskey: String? = "BD3690EC52B779A30344A52A84D00AD9"//"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
    var didAttemptUnlocking = false
    var beaconGATTOperations: GATTOperations?
    var beaconOperationsCallback: ((_ operationState: OperationState) -> Void)?
    var lockStateCallback: ((_ lockState: LockState) -> Void)?
    var updateLockStateCallback: ((_ lockState: LockState) -> Void)?
    var remainConnectableCallback: (() -> Void)?
    var factoryResetCallback: (() -> Void)?

    var user: AWSCognitoIdentityUser?
    
    var isMenuShown:Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        
        UIApplication.shared.statusBarStyle = .lightContent
        guard let thisUser = user else { return }
        emailLabel.text = thisUser.username
        
        if thisUser.isSignedIn && !isMenuShown { refresh(self) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nc = NotificationCenter.default // Note that default is now a property, not a method call
        nc.addObserver(forName:Notification.Name(rawValue:"userSignedIn"),
                       object:nil, queue:nil,
                       using:catchNotification)

        let pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        user = pool.currentUser()
        
        tableView.separatorColor = UIColor.clear
        self.title = "Parabit Beacon Configuration"
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = UIColor.orange
        let btn1 = UIButton(type: .custom)
        btn1.setImage(UIImage(named: "menu"), for: .normal)
        btn1.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn1.addTarget(self, action: #selector(BeaconFinderViewController.showMenu), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: btn1)
        
        self.navigationItem.setLeftBarButton(item1, animated: true)
        
        self.tableView.separatorColor = UIColor.clear
        
        guard let isSignedIn = user?.isSignedIn else { return }
        if !isSignedIn { return }
        centralManager = CBCentralManager(delegate: self,
                                          queue: nil)
        //temp hack to get user attributes
        shouldShowSignIn()
        
    }
    
    func showMenu() {
        if isMenuShown {
            UIView.animate(withDuration: 0.5) {
                self.menuView.frame = CGRect(x: -265, y: self.menuView.frame.origin.y, width: 265, height: self.menuView.frame.height)
                    self.isMenuShown = false
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.menuView.frame = CGRect(x: 0, y: self.menuView.frame.origin.y, width: 265, height: self.menuView.frame.height)
                    self.isMenuShown = true
                }
        }
    }
    
    
    @IBAction func homeTapped(_ sender: Any) {
        showMenu()
        guard let user = self.user else { return }
    }
    
    @IBAction func helpTapped(_ sender: Any) {
    
        guard let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return }
        let date = "01-18-2018"
        let message = "Parabit Technician App \n Version: \(versionNumber) \n Date: \(date)"
        let alert = UIAlertController(title: "About", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        guard let user = self.user else { return }
        EventsLogger.sharedInstance.logEvent(event: "MENU_HELP", info: ["username":user.username ?? ""])

    }
    
    @IBAction func profileTapped(_ sender: Any) {
        return // disabling feature for now
        
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "attributesView") as? UserDetailTableViewController else { return }
        self.navigationController?.pushViewController(vc, animated: true)
        
        guard let user = self.user else { return }

    }
    
    @IBAction func signOutTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Sign Out", message: "Are you sure you would like to sign out?", preferredStyle: UIAlertControllerStyle.alert) //Replace UIAlertControllerStyle.Alert by UIAlertControllerStyle.alert
        
        let okAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) {
            (result : UIAlertAction) -> Void in
            print("OK")
            EventsLogger.sharedInstance.logEvent(event: "LOGOUT", info: ["username":self.user?.username ?? ""])

            self.user?.signOut()
            self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
                return nil
            }
        }
        
        let DestructiveAction = UIAlertAction(title: "No", style: UIAlertActionStyle.destructive) {
            (result : UIAlertAction) -> Void in
            print("No")
        }
        
        alertController.addAction(okAction)
        alertController.addAction(DestructiveAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func feedbackTapped(_ sender: Any) {

        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackController") as? FeedbackViewController else { return }
        self.navigationController?.pushViewController(vc, animated: true)
        
        guard let user = self.user else { return }
        EventsLogger.sharedInstance.logEvent(event: "MENU_FEEDBACK", info: ["username":user.username ?? ""])
    }
    
    @IBAction func reportProblemTapped(_ sender: Any) {
        
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ReportProblemController") as? ReportProblemViewController else { return }
        self.navigationController?.pushViewController(vc, animated: true)
        
        guard let user = self.user else { return }
        EventsLogger.sharedInstance.logEvent(event: "MENU_REPORT_PROBLEM", info: ["username":user.username ?? ""])
        
    }

    @IBAction func refresh(_ sender: Any) {
        //temp hack to get user attributes
        shouldShowSignIn()
        
        self.resetBluetooth()
        guard let user = self.user else { return }
        EventsLogger.sharedInstance.logEvent(event: "BEACON_SCAN", info: ["username":user.username ?? ""])
    }
    
    func resetBluetooth () {
        
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self,queue: nil)
        }
        
        SwiftSpinner.show(duration: 3, title: "Scanning")
        let when = DispatchTime.now() + 0 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.sensorTag = nil
            self.currentBeacon = nil
            self.beaconInvestigation = nil
            self.eddystoneService = nil
            self.deviceInformationService = nil
            self.availableDoors = []
            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
            self.currentBeacon?.isUnlocked = false
            self.isBeaconUnlocked = false
            self.tableView.reloadData()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 6) {
            self.centralManager.stopScan()
        }
    }
    
    func shouldShowSignIn() {
        if ParabitNetworking.sharedInstance.userAttributes == nil {
            ParabitNetworking.sharedInstance.getAuthenticationKeys()
        }
    }
    
    //Mark: Notification
    func catchNotification(notification:Notification) -> Void {
        print("Catch notification")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.refresh(self)
        }
    }
    
}
