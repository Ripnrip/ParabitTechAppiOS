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
import Foundation
import CoreBluetooth

let kBroadCastCapabilitiesVersion: UInt8 = 0
let kBroadcastCapabilitiesPerSlotAdvIntervals: UInt8 = 0x1
let kBroadcastCapabilitiesPerSlotTxPower: UInt8 = 0x2
let kBroadcastCapabilitiesSupportsUID: UInt8 = 0x1
let kBroadcastCapabilitiesSupportsURL: UInt8 = 0x2
let kBroadcastCapabilitiesSupportsTLM: UInt8 = 0x4
let kBroadcastCapabilitiesSupportsEID: UInt8 = 0x8

let maxSupportedSlotsKey = "maxSupportedSlots"
let maxSupportedEIDSlotsKey = "maxSupportedEIDSlots"
let perSlotAdvIntervalsSupportedKey = "advertismentIntervalSupported"
let perSlotTxPowerSupportedKey = "txPowerSupported"
let UIDSupportedKey = "UIDSupportedKey"
let URLSupportedKey = "URLSupportedKey"
let TLMSupportedKey = "TLMSupportedKey"
let EIDSupportedKey = "EIDSupportedKey"
let BroadcastCapabilitiesSupportsEID = "BroadcastCapabilitiesSupportsEID"

let slotDataFrameTypeKey = "slotDataFrameTypeKey"
let slotDataUIDKey = "slotDataUIDKey"
let slotDataURLKey = "slotDataURLKey"
let slotDataTLMKey = "slotDataTLMKey"
let slotDataEIDKey = "slotDataEIDKey"
let slotDataAdvIntervalKey = "slotDataAdvIntervalKey"
let slotDataTxPowerKey = "slotDataTxPowerKey"
let slotDataNoFrameKey = "slotDataNoFrameKey"
let slotDataRemainConnectableKey = "slotDataRemainCOnnectableKey"


///
/// The class wants to read all the information for the beacon.
/// We have to discover the capabilities and get information such as the maximum number of
/// slots that are available, and then, for each slot, we want to read the TX Power, the
/// advertising interval and the actual slot data. We actually created a nice flow for this
/// to make things look cleaner and to be able to handle errors.
///
class BeaconInvestigation: GATTOperations {

  var currentlyScannedSlot: UInt8 = 0
  var beaconBroadcastCapabilities: NSDictionary = [:]
  var slotData = [NSNumber : [ String : NSData]]()
    var callback: ((_ beaconBroadcastCapabilities: NSDictionary,
    _ slotData: Dictionary <NSNumber, Dictionary <String, NSData>>) -> Void)?

  enum InvestigationState {
    case BeaconUnlocked
    case DiscoveredCapabilities
    case ErrorDiscoveringCapabilities
    case DidSetActiveSlot
    case ErrorSettingActiveSlot
    case ScannedSlot
    case ScannedAllSlots
    case ErrorScanningSlot
    case DidReadTxPower
    case ErrorReadingTxPower
    case DidReadAdvertisingInterval
    case ErrorReadingAdvertisingInterval
    case DidReadRemainConnectableState
    case ErrorReadingRemainCOnectableState
  }

  func didUpdateInvestigationState(investigationState: InvestigationState) {
    switch investigationState {
    case InvestigationState.BeaconUnlocked:
      discoverCapabilities()
    case InvestigationState.DiscoveredCapabilities:
      setSlotForScan()
    case InvestigationState.DidSetActiveSlot:
      scanSlot()
    case InvestigationState.ScannedSlot:
      readTxPower()
    case InvestigationState.DidReadTxPower:
      readAdvertisingInterval()
    case InvestigationState.DidReadAdvertisingInterval:
      readRemainConnectableState()
    case InvestigationState.DidReadRemainConnectableState:
      setSlotForScan()
    case InvestigationState.ScannedAllSlots:
      if let investigationCallback = callback {
        investigationCallback(beaconBroadcastCapabilities,
                              slotData)
      }
    case InvestigationState.ErrorScanningSlot:
      currentlyScannedSlot += 1;
      setSlotForScan()
    default:
      return
    }
  }

  func finishedUnlockingBeacon(investigationCallback:
    @escaping (_ beaconBroadcastCapabilities: NSDictionary,
    _ slotData: Dictionary <NSNumber, Dictionary <String, NSData>>) -> Void) {
    callback = investigationCallback
    peripheral.delegate = self
    didUpdateInvestigationState(investigationState: InvestigationState.BeaconUnlocked)
  }

  func discoverCapabilities() {
    if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.capabilities.UUID) {
        peripheral.readValue(for: characteristic)
    }
  }

  override func peripheral(peripheral: CBPeripheral,
                           didUpdateValueForCharacteristic characteristic: CBCharacteristic,
                                                           error: NSError?) {
    NSLog("did update value for characteristic \(characteristic.uuid)")
    if let identifiedError = error {
      NSLog("Error reading characteristic: \(identifiedError)")
    } else {
        switch characteristic.uuid {
      case CharacteristicID.capabilities.UUID:
        didReadBroadcastCapabilities()
      case CharacteristicID.ADVSlotData.UUID:
        didReadSlotData()
      case CharacteristicID.radioTxPower.UUID:
        didReadTxPower()
      case CharacteristicID.advertisingInterval.UUID:
        didReadAdvertisingInterval()
      case CharacteristicID.remainConnectable.UUID:
        didReadRemainConnectableState()
      default:
        return
      }
    }
  }

  override func peripheral(peripheral: CBPeripheral,
                           didWriteValueForCharacteristic characteristic: CBCharacteristic,
                                                          error: NSError?) {

    NSLog("did write value for characteristic \(characteristic.uuid)")
    if characteristic.uuid == CharacteristicID.activeSlot.UUID {
      if error != nil {
        didUpdateInvestigationState(investigationState: InvestigationState.ErrorSettingActiveSlot)
      } else {
        didUpdateInvestigationState(investigationState: InvestigationState.DidSetActiveSlot)
      }
    }
  }

  struct EddystoneGATTBroadcastCapabilities {
    var version: UInt8
    var maxSupportedTotalSlots: UInt8
    var maxSupportedEidSlots: UInt8
    var capabilitiesBitField: UInt8
    var supportedFrameTypesBitFieldHigh: UInt8
    var supportedFrameTypesBitFieldLow: UInt8

    init() {
      version = 0
      maxSupportedTotalSlots = 0
      maxSupportedEidSlots = 0
      supportedFrameTypesBitFieldLow = 0
      supportedFrameTypesBitFieldHigh = 0
      capabilitiesBitField = 0
    }
  }

  func isBitOn(field: UInt8, mask: UInt8) -> Bool {
    return (field & mask) != 0
  }

  func didReadBroadcastCapabilities() {
    if let capabilitiesCharacteristic = findCharacteristicByID(characteristicID: CharacteristicID.capabilities.UUID),
        let capabilities = capabilitiesCharacteristic.value {
        if capabilities.count < MemoryLayout<EddystoneGATTBroadcastCapabilities>.size {
        didUpdateInvestigationState(investigationState: InvestigationState.ErrorDiscoveringCapabilities)
      } else {
        var broadcastCapabilities = EddystoneGATTBroadcastCapabilities()
            
//            var values = [UInt8](repeating:0, count:data!.count)
//            data.copyBytes(to: &values, count: data!.count)
            
            //capabilities.copyBytes(to:&broadcastCapabilities, count: capabilities.length)
        if broadcastCapabilities.version != kBroadCastCapabilitiesVersion {
            didUpdateInvestigationState(investigationState: InvestigationState.ErrorDiscoveringCapabilities)
        } else {
          let txPowers: NSMutableArray = []
          var i = 6
            while i < capabilities.count {
            var txPower: Int8 = 0
                //capabilities.getBytes(&txPower, range:NSMakeRange(i, sizeof(Int8)))
                txPowers.add(NSNumber(value: txPower))
            i += 1
          }

          beaconBroadcastCapabilities =
            [maxSupportedSlotsKey :
                NSNumber(value: broadcastCapabilities.maxSupportedTotalSlots),
             maxSupportedEIDSlotsKey :
                NSNumber(value: broadcastCapabilities.maxSupportedEidSlots),
             perSlotAdvIntervalsSupportedKey :
                isBitOn(field: broadcastCapabilities.capabilitiesBitField,
                mask: kBroadcastCapabilitiesPerSlotAdvIntervals),
             perSlotTxPowerSupportedKey :
                isBitOn(field: broadcastCapabilities.capabilitiesBitField,
                mask: kBroadcastCapabilitiesPerSlotTxPower),
             UIDSupportedKey :
                isBitOn(field: broadcastCapabilities.supportedFrameTypesBitFieldLow,
                mask: kBroadcastCapabilitiesSupportsUID),
             URLSupportedKey :
                isBitOn(field: broadcastCapabilities.supportedFrameTypesBitFieldLow,
                mask: kBroadcastCapabilitiesSupportsURL),
             TLMSupportedKey :
                isBitOn(field: broadcastCapabilities.supportedFrameTypesBitFieldLow,
                mask: kBroadcastCapabilitiesSupportsTLM),
             EIDSupportedKey :
                isBitOn(field:broadcastCapabilities.supportedFrameTypesBitFieldLow,
                mask: kBroadcastCapabilitiesSupportsEID)]
          currentlyScannedSlot = 0
            didUpdateInvestigationState(investigationState: InvestigationState.DiscoveredCapabilities)
        }
      }
    }
  }

  func setSlotForScan() {
    if let maxSupportedSlots = beaconBroadcastCapabilities[maxSupportedSlotsKey] {
      let intMaxSupportedSlots: Int = maxSupportedSlots as! Int
      if currentlyScannedSlot >= UInt8(intMaxSupportedSlots) {
        didUpdateInvestigationState(investigationState: InvestigationState.ScannedAllSlots)
      } else {
        if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.activeSlot.UUID) {
          let currentSlot = NSData(bytes: &currentlyScannedSlot, length: 1)
            peripheral.writeValue(currentSlot as Data,
                                  for: characteristic,
                                  type: CBCharacteristicWriteType.withResponse)
        }
      }
    }
  }

  func scanSlot() {
    if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.ADVSlotData.UUID) {
        peripheral.readValue(for: characteristic)
    }
  }

  func didReadSlotData() {
    if let
        characteristic = findCharacteristicByID(characteristicID: CharacteristicID.ADVSlotData.UUID),
        let value = characteristic.value {
        updateSlotData(value: value as NSData)
    }
  }

  func updateSlotData(value: NSData) {
    var frameTypeName: String!
    if value.length > 0 {
        let scannedSlot: NSNumber = NSNumber(value: currentlyScannedSlot)
      var frameType: UInt8 = 0
      value.getBytes(&frameType, range: NSMakeRange(0, 1))

      if slotData[scannedSlot] == nil {
        slotData[scannedSlot] = [String : NSData]()
      }

      if frameType == BeaconInfo.EddystoneUIDFrameTypeID {
        frameTypeName = BeaconInfo.EddystoneFrameType.UIDFrameType.description
        slotData[scannedSlot]![slotDataFrameTypeKey] =
            frameTypeName.data(using: String.Encoding.utf8) as! NSData
        ///
        /// If the frame doesn't have enough characters, it means that the UID is malformed
        /// and no data is saved for this slot.
        ///
        if value.length >= 18 {
          ///
          /// The first two bytes represent frame type and ranging data. The rest of 16 bytes
          /// represent the UID - 10-byte Namespace and 6-byte Instance. If the frame has more
          /// bytes, we will simply truncate it to the ones we need.
          ///
            slotData[scannedSlot]![slotDataUIDKey] = value.subdata(with: NSMakeRange(2, 16)) as NSData
        }
      } else if frameType == BeaconInfo.EddystoneURLFrameTypeID {
        frameTypeName = BeaconInfo.EddystoneFrameType.URLFrameType.description
        slotData[scannedSlot]![slotDataFrameTypeKey] =
            frameTypeName.data(using: String.Encoding.utf8) as! NSData
        if let
            urlData = BeaconInfo.parseURLFromFrame(frameData: value),
            let urlNSData = urlData.absoluteString!.data(using: String.Encoding.utf8) {
          NSLog("\(slotData[scannedSlot]![slotDataFrameTypeKey])")
            slotData[scannedSlot]![slotDataURLKey] = urlNSData as NSData
        }
      } else if frameType == BeaconInfo.EddystoneTLMFrameTypeID {
        frameTypeName = BeaconInfo.EddystoneFrameType.TelemetryFrameType.description
        slotData[scannedSlot]![slotDataFrameTypeKey] =
            frameTypeName.data(using: String.Encoding.utf8) as! NSData
        slotData[scannedSlot]![slotDataTLMKey] = value
      } else if frameType == BeaconInfo.EddystoneEIDFrameTypeID {
        frameTypeName = BeaconInfo.EddystoneFrameType.EIDFrameType.description
        slotData[scannedSlot]![slotDataFrameTypeKey] =
            frameTypeName.data(using: String.Encoding.utf8) as! NSData
      }
        didUpdateInvestigationState(investigationState: InvestigationState.ScannedSlot)
    } else {
        let scannedSlot: NSNumber = NSNumber(value: currentlyScannedSlot)
      if slotData[scannedSlot] == nil {
        slotData[scannedSlot] = [String : NSData]()
      }
      frameTypeName = BeaconInfo.EddystoneFrameType.NotSetFrameType.description
      slotData[scannedSlot]![slotDataFrameTypeKey] =
        frameTypeName.data(using: String.Encoding.utf8 ) as! NSData

        didUpdateInvestigationState(investigationState: InvestigationState.ErrorScanningSlot)
    }
  }

  func readTxPower() {
    if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.radioTxPower.UUID) {
        peripheral.readValue(for: characteristic)
    }
  }

  func getValueForCharacteristic(characteristicID: CBUUID) -> NSData? {
    if let
        characteristic = findCharacteristicByID(characteristicID: characteristicID),
        let value = characteristic.value {
        return value as NSData
    }
    return nil
  }

  func didReadTxPower() {
    let scannedSlot: NSNumber = NSNumber(value: currentlyScannedSlot)
    var txPower: Int8 = 0
    if let value = getValueForCharacteristic(characteristicID: CharacteristicID.radioTxPower.UUID) {
        value.getBytes(&txPower, length: MemoryLayout<Int8>.size)
    }
    if slotData[scannedSlot] != nil {
        slotData[scannedSlot]![slotDataTxPowerKey] = NSData(bytes: &txPower, length: MemoryLayout<Int8>.size)
    }
    didUpdateInvestigationState(investigationState: InvestigationState.DidReadTxPower)
  }

  func readAdvertisingInterval() {
    if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.advertisingInterval.UUID) {
        peripheral.readValue(for: characteristic)
    }
  }


  func didReadAdvertisingInterval() {
    let scannedSlot: NSNumber = NSNumber(value: currentlyScannedSlot)
    var advertisingInterval: UInt16 = 0
    if let value = getValueForCharacteristic(characteristicID: CharacteristicID.advertisingInterval.UUID) {
        value.getBytes(&advertisingInterval, length: MemoryLayout<UInt16>.size)
    }
    if slotData[scannedSlot] != nil {
      var littleEndianAdvInterval: UInt16 = CFSwapInt16BigToHost(advertisingInterval)
      let bytes = NSData(bytes: &littleEndianAdvInterval,
                         length: MemoryLayout<UInt16>.size)
      slotData[scannedSlot]![slotDataAdvIntervalKey] = bytes
    }
    didUpdateInvestigationState(investigationState: InvestigationState.DidReadAdvertisingInterval)
  }

  func readRemainConnectableState() {
    if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.remainConnectable.UUID) {
        peripheral.readValue(for: characteristic)
    }
  }

  func didReadRemainConnectableState() {
    let scannedSlot: NSNumber = NSNumber(value: currentlyScannedSlot)
    if let value = getValueForCharacteristic(characteristicID: CharacteristicID.remainConnectable.UUID) {
      if slotData[scannedSlot] != nil {
        slotData[scannedSlot]![slotDataRemainConnectableKey] = value
      }
    }
    currentlyScannedSlot += 1
    didUpdateInvestigationState(investigationState: InvestigationState.DidReadRemainConnectableState)
  }
}
