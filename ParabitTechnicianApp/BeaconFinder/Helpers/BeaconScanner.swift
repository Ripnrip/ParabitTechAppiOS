// Copyright 2016 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import CoreBluetooth

let kBeaconConnectionMaxTimePermitted = 10
let kGetBeaconsServer = "https://proximitybeacon.googleapis.com/v1beta1/beacons/"
let kEddystoneEIDCode = 4
let kBeaconScanTime = 5
let kBeaconDataRequestTimeout = 15

enum OperationState: String {
  case Connected
  case DidDiscoverServices
  case DiscoveringServicesError
  case NotImplementingGATTConfigService
  case DidDiscoverCharacteristics
  case DiscoveringCharacteristicsError
  case ConnectionTimeout
  case CentralManagerConnectionError
  case DidFailToConnect
  case Unknown

  var name: String? {
    switch self {
    case .DiscoveringServicesError:
      return "Discovering Services Error"
    case .DiscoveringCharacteristicsError:
      return "Discovering Characteristics Error"
    case .ConnectionTimeout:
      return "Connection Timeout"
    case .CentralManagerConnectionError:
      return "Central Manager Error"
    case .DidFailToConnect:
      return "Connect Failed"
    case .NotImplementingGATTConfigService:
      return "GATT Configuratin Service"
    default:
      return nil
    }
  }

  var description: String? {
    switch self {
    case .DiscoveringServicesError:
      return "The services could not be discovered."
    case .DiscoveringCharacteristicsError:
      return "The characteristics could not be discovered."
    case .ConnectionTimeout:
      return "The process of connecting to the beacon timed out."
    case .CentralManagerConnectionError:
      return "Central Manager is not ready."
    case .DidFailToConnect:
      return "Connecting to the beacon failed."
    case .NotImplementingGATTConfigService:
      return "The beacon does not implement the GATT configuration service."
    default:
      return nil
    }
  }

}

extension CBCentralManager {
  internal var centralManagerState: CBCentralManagerState  {
    get {
        return CBCentralManagerState(rawValue: state.rawValue) ?? .unknown
    }
  }
}

///
/// BeaconScanner
///
class BeaconScanner: NSObject, CBCentralManagerDelegate,CBPeripheralDelegate {
  /// Dictionary holding the frames supported by each beacon that we find while scanning
  var beaconsFound = [CBPeripheral : BeaconFramesSupported]()
  var connectingTime = 0
  var scanningTime = 0
  var gettingBeaconDataTime = 0
  var scanningTimer: Timer?
  var connectionTimer: Timer?
  var gettingBeaconDataTimer: Timer?
  var lockQueue: DispatchQueue
  var lockQueueForBeaconData: DispatchQueue
  var didFinishScanningCallback: (() -> Void)?
  var outstandingBeaconRequests: Int = 0
  var activelyScanning = false

  ///
  /// When discovering a beacon which broadcasts an EID frame, we need to make a HTTP Get
  /// request to see if the beacon was registered with the project that the current user
  /// has selected, which means that the beacon belongs to the user.
  ///
  var myEIDBeacons: NSMutableDictionary = [:]
  private var operationState: OperationState
  private var centralManager: CBCentralManager!
  private var connectingPeripheral: CBPeripheral!
  private let beaconOperationsQueue: DispatchQueue =
  DispatchQueue(label: "beacon_operations_queue")
  private var shouldBeScanning: Bool = false
  private var GATTOperationCallback:((_ operationState: OperationState) -> Void)?
  var lockStateCallback: ((_ lockState: LockState) -> Void)?
  var updateLockStateCallback: ((_ lockState: LockState) -> Void)?
    
  var userPasskey: String? = "BD3690EC52B779A30344A52A84D00AD9"
  var didAttemptUnlocking = false


  override init() {
    self.operationState = OperationState.Unknown
    self.lockQueue = DispatchQueue(label:"LockQueue")
    self.lockQueueForBeaconData = DispatchQueue(label:"LockQueueForBeaconData")
    super.init()
    self.centralManager = CBCentralManager(delegate: self, queue: self.beaconOperationsQueue)
    self.centralManager.delegate = self
  }

  ///
  /// Start scanning. If Core Bluetooth isn't ready for us just yet, then waits and THEN starts
  /// scanning.
  ///
    func startScanning(completionHandler: @escaping () -> Void) {
    myEIDBeacons.removeAllObjects()
    didFinishScanningCallback = completionHandler
    scanningTime = kBeaconScanTime
    activelyScanning = true
    scanningTimer = Timer.scheduledTimer(
        timeInterval: 1.0,
      target: self,
      selector: #selector(BeaconScanner.subtractScanningTime),
      userInfo: nil,
      repeats: true)
        self.beaconOperationsQueue.async() {
      self.startScanningSynchronized()
    }
    if EIDConfiguration.projectID != nil {
      gettingBeaconDataTime = kBeaconDataRequestTimeout
        gettingBeaconDataTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
        target: self,
        selector: #selector(BeaconScanner.subtractGettingBeaconDataTime),
        userInfo: nil,
        repeats: true)
    }
  }

    @objc func subtractScanningTime() {
    scanningTime -= 1
    if scanningTime == 0 {
      self.stopScanning()
    }
  }

    @objc func subtractGettingBeaconDataTime() {
    gettingBeaconDataTime -= 1
    if gettingBeaconDataTime == 0 {
      if let currentTimer = gettingBeaconDataTimer {
        currentTimer.invalidate()
        gettingBeaconDataTimer = nil
      }
      if let callback = didFinishScanningCallback {
        callback()
      }
    }
  }

  ///
  /// Stops scanning for Eddystone beacons.
  ///
  func stopScanning() {
    self.centralManager.stopScan()
    if let currentTimer = scanningTimer {
      currentTimer.invalidate()
    }
    activelyScanning = false

    /// Check if we received all the beacon data by now.
    var outstandingRequests: Int = 0
    lockQueueForBeaconData.sync {
      outstandingRequests = self.outstandingBeaconRequests
    }

    if (outstandingRequests == 0 || gettingBeaconDataTimer == nil) {
      if let callback = didFinishScanningCallback {
        callback()
      }
    }
  }

  ///
  /// MARK - private methods and delegate callbacks
  ///
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.centralManagerState == CBCentralManagerState.poweredOn && self.shouldBeScanning {
      self.startScanningSynchronized()
    }
  }

  ///
  /// Core Bluetooth CBCentralManager callback when we discover a beacon. We're not super
  /// interested in any error situations at this point in time, we only parse each frame
  /// and save it.
  ///
 
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey) and UUID is \(peripheral.identifier.uuidString)\"")
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            print("NEXT PERIPHERAL STATE: \(peripheral.state.rawValue)")
            if peripheralName == "Parabeacon" {
                print("SENSOR TAG FOUND! ADDING NOW!!!")
                // to save power, stop scanning for other devices
                activelyScanning = false
                stopScanning()
                
                // save a reference to the sensor tag
                connectingPeripheral = peripheral
                connectingPeripheral.delegate = self
                
                //add peripheral to available doors tableview
//                let paraDoor = Peripheral(name: peripheralName, UUID: peripheral.identifier.uuidString, isConnectable: true, sensorTag: sensorTag)
//                availableDoors.append(paraDoor)
//                doorsTableView.reloadData()
                
                //connect
                centralManager.connect(peripheral, options: nil)
            }
        }
    }
  func didUpdateState(operationState: OperationState) {
    self.operationState = operationState

    if let currentTimer = connectionTimer {
      currentTimer.invalidate()
    }
    if  operationState == OperationState.Connected {
      if let beaconGATTOperations = beaconsFound[connectingPeripheral]?.operations {
        if let callback = GATTOperationCallback {
            beaconGATTOperations.discoverServices(callback: callback)
        }
      }
    } else if let UICallback = GATTOperationCallback {
        UICallback(operationState)
    }
  }

  ///
  /// Attempts to connect to a beacon if the CB Central Manager is ready;
  /// We set a timer because we assume that if the connection can't be established in that
  /// amount of time, there's a problem that the user needs to consider.
  ///
  func connectToBeacon(peripheral: CBPeripheral,
                       callback: @escaping (_ operationState: OperationState) -> Void) {
    GATTOperationCallback = callback
    if self.centralManager.centralManagerState == CBCentralManagerState.poweredOn {
      connectingPeripheral = peripheral
        if peripheral.state != CBPeripheralState.connected {
        self.connectToPeripheralWithTimeout(peripheral: connectingPeripheral)
      } else {
        if let beaconGATTOperations = beaconsFound[connectingPeripheral]?.operations {
            beaconGATTOperations.discoverServices(callback: callback)
        }
      }
    } else {
      NSLog("CentralManager state is %d, cannot connect", self.centralManager.state.rawValue)
        didUpdateState(operationState: OperationState.CentralManagerConnectionError)
    }
  }

  func connectToPeripheralWithTimeout(peripheral: CBPeripheral) {
    self.setupTimer()
    centralManager.connect(connectingPeripheral, options: nil)
  }

  func setupTimer() {
    connectingTime = kBeaconConnectionMaxTimePermitted
    connectionTimer = Timer.scheduledTimer(
        timeInterval: 1.0,
      target: self,
      selector: #selector(BeaconScanner.subtractConnectingTime),
      userInfo: nil,
      repeats: true)
  }

    @objc func subtractConnectingTime() {
    connectingTime -= 1
    if connectingTime == 0 {
      centralManager.cancelPeripheralConnection(connectingPeripheral)
        didUpdateState(operationState: OperationState.ConnectionTimeout)
    }
  }

  func centralManager(central: CBCentralManager,
                      didFailToConnectPeripheral peripheral: CBPeripheral,
                                                 error: NSError?) {
    NSLog("Connecting failed");
    ///
    /// Other situations in which the connection attempt fails,
    /// the timeout being treated separately.
    ///
    if operationState != OperationState.ConnectionTimeout {
        didUpdateState(operationState: OperationState.DidFailToConnect)
    }
  }

    // Discover services of the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!")
        didUpdateState(operationState: OperationState.Connected)

        
        // Now that we've successfully connected to the SensorTag, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        peripheral.discoverServices(nil)
    }
    
    /*
     Invoked after connecting to a peripheral; didDiscoverServices lists the services
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("there was an error discovering the services after connecting \(String(describing: error))")
        }
        didUpdateState(operationState: OperationState.DidDiscoverServices)
        guard let services = peripheral.services else {return}
        print("The discovered services are \(services))")
        peripheral.discoverCharacteristics(nil, for: peripheral.services![0])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("there was an error discovering characteristics for a service")
        }
        didUpdateState(operationState: OperationState.DidDiscoverCharacteristics)
        guard let characteristics = service.characteristics else {return}
        print("The discovered characteristics are \(characteristics))")
        characteristics.forEach { (characteristic) in
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("there was an error discovering the characteristics \(characteristic) from \(connectingPeripheral)")
        }
        print("the updated values for characteristic \(characteristic)")
        if characteristic.uuid == CharacteristicID.lockState.UUID {
            print("****PARSE LOCK STATE VALUE****")
            parseLockStateValue()
        } else if characteristic.uuid == CharacteristicID.unlock.UUID {
            print("****UNLOCK BEACON****")
            unlockBeaconWithCharacteristic(characteristic: characteristic)
        }
    }

    func parseLockStateValue() {
        if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.lockState.UUID),
            let value = characteristic.value {
            if value.count == 1 {
                let lockState = value.withUnsafeBytes { (ptr: UnsafePointer<Int>) in
                    ptr.pointee
                }
                if lockState == LockState.Locked.rawValue {
                    NSLog("The beacon is locked :( .")
                    didUpdateLockState(lockState: LockState.Locked)
                } else {
                    NSLog("The beacon is unlocked!")
                    didUpdateLockState(lockState: LockState.Unlocked)
                }
            }
        }
    }
    
    func findCharacteristicByID(characteristicID: CBUUID) -> CBCharacteristic? {
        if let services = connectingPeripheral.services {
            for service in services {
                for characteristic in service.characteristics! {
                    if characteristic.uuid == characteristicID {
                        return characteristic
                    }
                }
            }
        }
        return nil
    }

    func didUpdateLockState(lockState: LockState) {
        if let callback = lockStateCallback {
            switch lockState {
            case LockState.Locked:
                if userPasskey != nil {
                    if didAttemptUnlocking {
                        callback(LockState.Locked)
                    } else {
                        getUnlockChallenge()
                    }
                } else {
                    callback(LockState.Locked)
                }
            case LockState.Unlocked:
                callback(LockState.Unlocked)
            default:
                callback(LockState.Unknown)
            }
        }
    }
    
    func getUnlockChallenge() {
        if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.unlock.UUID) {
            connectingPeripheral.readValue(for: characteristic)
        }
    }
    
    func unlockBeaconWithCharacteristic(characteristic:CBCharacteristic) {
        print("the value of the characteristic is \(characteristic)")
        guard let unlockChallenge = characteristic.value else {return}
        let token: NSData? = AESEncrypt(data: unlockChallenge as NSData, key: userPasskey)
        // erase old password
        userPasskey = nil
        didAttemptUnlocking = true
        if let unlockToken = token {
            connectingPeripheral.writeValue(unlockToken as Data,
                                            for: characteristic,
                                            type: CBCharacteristicWriteType.withResponse)
        }

    }
    
    func AESEncrypt(data: NSData, key: String?) -> NSData? {
        if let passKey = key {
            let keyBytes = StringUtils.transformStringToByteArray(string: passKey)
            let cryptData = NSMutableData(length: Int(data.length) + kCCBlockSizeAES128)!
            let operation: CCOperation = UInt32(kCCEncrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
            let options:   CCOptions   = UInt32(kCCOptionECBMode)
            var numBytesEncrypted :size_t = 0
            let cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      keyBytes,
                                      keyBytes.count,
                                      nil,
                                      data.bytes,
                                      data.length,
                                      cryptData.mutableBytes,
                                      cryptData.length,
                                      &numBytesEncrypted)
            
            if Int(cryptStatus) == Int(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                return cryptData as NSData
            } else {
                NSLog("Error: \(cryptStatus)")
                
            }
        }
        return nil
    }
    
    
    
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    NSLog("Beacon connected")
    didUpdateState(operationState: OperationState.Connected)
  }

  func disconnectFromBeacon(peripheral: CBPeripheral) {
    if self.centralManager.centralManagerState == CBCentralManagerState.poweredOn {
      centralManager.cancelPeripheralConnection(peripheral)
    } else {
      NSLog("CentralManager state is %d, cannot disconnect", self.centralManager.state.rawValue)
    }
  }

  private func startScanningSynchronized() {
    if self.centralManager.centralManagerState != CBCentralManagerState.poweredOn {
      NSLog("CentralManager state is %d, cannot start scan", self.centralManager.state.rawValue)
      self.shouldBeScanning = true
    } else {
      NSLog("Starting to scan for Eddystones")
      let services = [CBUUID(string: "FEAA")]
      let options = [CBCentralManagerScanOptionAllowDuplicatesKey : true]
        //changin to nil for now to discover all beacons
        self.centralManager.scanForPeripherals(withServices: nil, options: nil)
        //self.centralManager.scanForPeripherals(withServices: services, options: options)
    }
  }

  /// Creates the array with all the necessary information to be displayed.
  func populateBeaconItems() -> [BeaconItem] {
    var beaconItems: [BeaconItem] = [BeaconItem]()
    for (beacon, frames) in beaconsFound {
      let beaconGATTOperations = beaconsFound[beacon]!.operations
      let beaconItem: BeaconItem = BeaconItem(peripheral: beacon,
                                              frames: frames,
                                              operations: beaconGATTOperations)
      if frames.containsUsefulFrames() {
        beaconItems.append(beaconItem)
      }

    }
    return beaconItems
  }

  /// Checkes whether or not an EID beacon was registered using this projectID.
  func getBeaconHTTPRequest(EID: String, projectID: String) {

  }
}
