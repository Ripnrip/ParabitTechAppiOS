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

let kEIDFrameLength = 14
///
/// Beacons need a couple of seconds to generate the correct EID ADV Slot data after writing out to
/// that slot and to generate the beacon ECDH public key, so we're waiting for them.
///
let kWaitingForBeaconTime: Double = 3
let kECDHLengthKey = 32
let kEIDLength = 8

///
/// We need a couple of things both from the beacon and the service and we want to make sure we
/// gather all of it and that it's correct.
///
class EIDRegistrationData {
  var beaconEcdhPublicKey: String?
  var serviceEcdhPublicKey: String?
  var rotationPeriodExponent: NSNumber?
  var initialClockValue: String?
  var initialEid: String?

  func isValid() -> Bool {
    return beaconEcdhPublicKey != nil &&
           serviceEcdhPublicKey != nil &&
           rotationPeriodExponent != nil &&
           initialClockValue != nil &&
           initialEid != nil
  }
}

class ConfigureBeaconSlotData: GATTOperations {
  var maxSupportedTotalSlots = 0
  var currentlyUpdatedSlot = 0
  var slotUpdateData = [NSNumber : [String : NSData]]()
  var beaconCapabilities: NSDictionary = [:]
  var callback: (() -> Void)?
  var isEIDSlot = false
  var registrationEIDData: EIDRegistrationData?
  var statusInfoUpdateAlert: UIAlertController?

  enum ConfigurationState {
    case ReceivedUpdateData
    case DidSetActiveSlot
    case ErrorSettingActiveSlot
    case DidUpdateTxPower
    case ErrorUpdatingTxPower
    case DidUpdateAdvInterval
    case ErrorUpdatingAdvInterval
    case DidUpdateSlotData
    case ErrorUpdatingSlotData
    case UpdatedAllSlots
  }

  func didUpdateConfigurationState(configurationState: ConfigurationState) {
    switch configurationState {
    case .ReceivedUpdateData:
      setActiveSlot()
    case .DidSetActiveSlot:
      updateTxPower()
    case .DidUpdateTxPower:
      updateAdvInterval()
    case .DidUpdateAdvInterval:
      updateSlotData()
    case .DidUpdateSlotData:
      ///
      /// The EID slot configuration is special and requires some extra steps:
      ///   * reading the exponent, the value and the initial EID from the slot
      ///   * reading the public ECDH Key
      ///
      if isEIDSlot {
        let delayTime = DispatchTime.now() + kWaitingForBeaconTime
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
          self.readEIDFrame()
        }
        isEIDSlot = false
      } else {
        currentlyUpdatedSlot += 1; setActiveSlot()
      }
    /// We're done!
    case .UpdatedAllSlots:
      if let UICallback = callback {
        UICallback()
      }
    ///
    /// If we have any problem with the update of the current slot, we just try to update the next
    /// one; there's no point in discarding all changes just because one failed.
    ///
    case .ErrorUpdatingSlotData:
      currentlyUpdatedSlot += 1; setActiveSlot()
    default:
      break
    }
  }

  func setActiveSlot() {
    if currentlyUpdatedSlot >= maxSupportedTotalSlots {
        didUpdateConfigurationState(configurationState: ConfigurationState.UpdatedAllSlots)
    } else {
        if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.activeSlot.UUID) {
        let currentSlot = NSData(bytes: &currentlyUpdatedSlot, length: 1)
            peripheral.writeValue(currentSlot as Data,
                                  for: characteristic,
                                  type: CBCharacteristicWriteType.withResponse)
      }
    }
  }

  override func peripheral(peripheral: CBPeripheral,
                           didWriteValueForCharacteristic characteristic: CBCharacteristic,
                                                          error: NSError?) {

    if error != nil {
        switch characteristic.uuid {
      case CharacteristicID.activeSlot.UUID:
        didUpdateConfigurationState(configurationState: ConfigurationState.ErrorSettingActiveSlot)
      case CharacteristicID.radioTxPower.UUID:
        didUpdateConfigurationState(configurationState: ConfigurationState.ErrorUpdatingTxPower)
      case CharacteristicID.advertisingInterval.UUID:
        didUpdateConfigurationState(configurationState: ConfigurationState.ErrorUpdatingAdvInterval)
      case CharacteristicID.ADVSlotData.UUID:
        didUpdateConfigurationState(configurationState: ConfigurationState.ErrorUpdatingSlotData)
      default:
        break
      }
    } else {
        switch characteristic.uuid {
      case CharacteristicID.activeSlot.UUID:
        didUpdateConfigurationState(configurationState: ConfigurationState.DidSetActiveSlot)
      case CharacteristicID.radioTxPower.UUID:
        didUpdateConfigurationState(configurationState: ConfigurationState.DidUpdateTxPower)
      case CharacteristicID.advertisingInterval.UUID:
        didUpdateConfigurationState(configurationState: ConfigurationState.DidUpdateAdvInterval)
      case CharacteristicID.ADVSlotData.UUID:
        didUpdateConfigurationState(configurationState: ConfigurationState.DidUpdateSlotData)
      default:
        break
      }
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
      case CharacteristicID.ADVSlotData.UUID:
        parseEIDFrame()
      case CharacteristicID.publicECDHKey.UUID:
        didReadPublicECDH()
      default: break
      }
    }
  }

  func readEIDFrame() {
    if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.ADVSlotData.UUID) {
        peripheral.readValue(for: characteristic)
    }
  }

  func readPublicECDH() {
    if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.publicECDHKey.UUID) {
        peripheral.readValue(for: characteristic)
    }
  }

  func didReadPublicECDH() {
    if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.publicECDHKey.UUID),
        let value = characteristic.value {
        // The ECDH public key's length is 32 bytes
        if value.count == kECDHLengthKey {
            var publicECDH = [UInt8](repeating: 0, count: kECDHLengthKey * MemoryLayout<UInt8>.size)
            //value.getBytes(&publicECDH, length: kECDHLengthKey * sizeof(UInt8))
            value.copyBytes(to: &publicECDH, count: publicECDH.count)
            let publicECDHBase64String = StringUtils.convertNSDataToBase64String(data: value as NSData)
        if let registrationData = registrationEIDData {
          registrationData.beaconEcdhPublicKey = publicECDHBase64String
          if registrationData.isValid() {
            /// If we have all the registration data, we can finally register the beacon.
            let configureEID = EIDConfiguration()
            configureEID.registerBeacon(registrationData: registrationData) { didRegister in
              if didRegister {
                self.didUpdateConfigurationState(configurationState: ConfigurationState.DidUpdateSlotData)
              } else {
                self.didUpdateConfigurationState(configurationState: ConfigurationState.ErrorUpdatingSlotData)
              }
            }
          } else {
            didUpdateConfigurationState(configurationState: ConfigurationState.ErrorUpdatingSlotData)
          }
        } else {
            didUpdateConfigurationState(configurationState: ConfigurationState.ErrorUpdatingSlotData)
        }
      }
    }
  }

  func parseEIDFrame() {
    if let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.ADVSlotData.UUID),
        let value = characteristic.value {
        let frameType = value.withUnsafeBytes { (ptr: UnsafePointer<Int>) in
            ptr.pointee
        }
        if frameType == BeaconInfo.EddystoneEIDFrameTypeID && value.count == kEIDFrameLength {
            // The EID Slot Data has the following structure:
            //    1 byte frame type
            //    1 byte exponent
            //    4 byte clock value
            //    8 byte EID
            var exponent:UInt8 = 0
            var clockValue: UInt32 = 0
            var EIDValue = [UInt8](repeating: 0, count: kEIDLength)
//            value.getBytes(&exponent, range: NSMakeRange(1, 1))
//            value.getBytes(&clockValue, range: NSMakeRange(2, 4))
//            value.getBytes(&EIDValue, range: NSMakeRange(6, 8))
            /// The clock value is in big endian format, so we want to convert it to little endian.
            clockValue = CFSwapInt32BigToHost(clockValue)
            if let registrationData = registrationEIDData {
                registrationData.rotationPeriodExponent = NSNumber(value: exponent)
                let clockValueString = "\(clockValue)"
                registrationData.initialClockValue = clockValueString
                let EIDData = NSData(bytes: EIDValue, length: kEIDLength)
                let EIDBase64String = StringUtils.convertNSDataToBase64String(data: EIDData)
                registrationData.initialEid = EIDBase64String
            }

            /// We're giving the beacon it needs to compute its public ECDH key.
            let delayTime = DispatchTime.now() + kWaitingForBeaconTime
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
              self.readPublicECDH()
        }
      } else {
        didUpdateConfigurationState(configurationState: ConfigurationState.ErrorUpdatingSlotData)
      }
    }
  }

  // TODO: possibly send as callback a list of errors that appeared while configuring slots
  func beginBeaconConfiguration(beaconCapabilities: NSDictionary,
                                statusInfoAlert: UIAlertController,
                                slotUpdateData: Dictionary <NSNumber, Dictionary <String, NSData>>,
                                callback: @escaping () -> Void) {
    self.callback = callback
    self.maxSupportedTotalSlots = beaconCapabilities[maxSupportedSlotsKey] as! Int
    self.currentlyUpdatedSlot = 0
    self.slotUpdateData = slotUpdateData
    self.beaconCapabilities = beaconCapabilities
    self.statusInfoUpdateAlert = statusInfoAlert
    peripheral.delegate = self
    didUpdateConfigurationState(configurationState: ConfigurationState.ReceivedUpdateData)
  }

  func updateTxPower() {
    var slotNumber = currentlyUpdatedSlot + 1
    if let perSlotTxPowerSupported = beaconCapabilities[perSlotTxPowerSupportedKey] {
      if !(perSlotTxPowerSupported as! Bool) {
        slotNumber = 0
      }
    }
    if let
    currentSlotData = slotUpdateData[NSNumber(value:slotNumber)],
        let value = currentSlotData[slotDataTxPowerKey],
        let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.radioTxPower.UUID) {
      var txPower: Int8 = 0
        value.getBytes(&txPower, length: MemoryLayout<Int8>.size)
        let val = NSData(bytes: &txPower, length: MemoryLayout<Int8>.size)
        peripheral.writeValue(val as Data, for: characteristic, type: .withResponse)
    } else {
      updateAdvInterval()
    }
  }

  func updateAdvInterval() {
    var slotNumber = currentlyUpdatedSlot + 1
    if let perSlotAdvIntervalSupported = beaconCapabilities[perSlotAdvIntervalsSupportedKey] {
      if !(perSlotAdvIntervalSupported as! Bool) {
        slotNumber = 0
      }
    }
    if let
    currentSlotData = slotUpdateData[NSNumber(value:slotNumber)],
        let value = currentSlotData[slotDataAdvIntervalKey],
        let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.advertisingInterval.UUID) {
      var advInterval: UInt16 = 0
        value.getBytes(&advInterval, length: MemoryLayout<UInt16>.size.self)
      var bigEndianAdvInterv: UInt16 = CFSwapInt16HostToBig(advInterval)
        let val = NSData(bytes: &bigEndianAdvInterv, length: MemoryLayout<UInt16>.size)
        peripheral.writeValue(val as Data, for: characteristic, type: .withResponse)
    } else {
      updateSlotData()
    }
  }

  ///
  /// We usually get the slot data in the right format from the moment when we create a dictionary
  /// with it. There's no need to do more computations.
  ///
  func updateSlotData() {
    isEIDSlot = false
    let slotNumber = currentlyUpdatedSlot + 1
    if let
        currentSlotData = slotUpdateData[NSNumber(value:slotNumber)],
        let value = currentSlotData[slotDataURLKey],
        let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.ADVSlotData.UUID) {
        peripheral.writeValue(value as Data, for: characteristic, type: .withResponse)
    } else if let
      currentSlotData = slotUpdateData[NSNumber(value:slotNumber)],
        let  value = currentSlotData[slotDataUIDKey],
        let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.ADVSlotData.UUID) {
        peripheral.writeValue(value as Data, for: characteristic, type: .withResponse)
    } else if let
      currentSlotData = slotUpdateData[NSNumber(value:slotNumber)],
        let value = currentSlotData[slotDataTLMKey],
        let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.ADVSlotData.UUID) {
        peripheral.writeValue(value as Data, for: characteristic, type: .withResponse)
    } else if let
      currentSlotData = slotUpdateData[NSNumber(value:slotNumber)],
        let value = currentSlotData[slotDataNoFrameKey],
        let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.ADVSlotData.UUID) {
        peripheral.writeValue(value as Data, for: characteristic, type: .withResponse)
    } else if let
      currentSlotData = slotUpdateData[NSNumber(value:slotNumber)],
        let _ = currentSlotData[slotDataEIDKey],
        let characteristic = findCharacteristicByID(characteristicID: CharacteristicID.ADVSlotData.UUID) {
      ///
      /// The EID configuration requires additional steps; we don't have the frameData yet and
      /// we must take it from the server. After writing it, we're still not done with this!
      ///
      isEIDSlot = true
      let configurationEID = EIDConfiguration()
      configurationEID.getEIDParams() {serviceKey, minRotationExponent, maxRotationExponent in
        if let
          key = serviceKey,
            let minExponent = minRotationExponent,
            let _ = maxRotationExponent {
          let frameData = NSMutableData()
            frameData.append([BeaconInfo.EddystoneEIDFrameTypeID], length: MemoryLayout<UInt8>.size.self)
          if let
            serviceKeyData = NSData(base64Encoded: key,
                                    options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) {
            frameData.append(serviceKeyData as Data)
            if serviceKeyData.length == kECDHLengthKey {
              self.registrationEIDData = EIDRegistrationData()
              self.registrationEIDData?.serviceEcdhPublicKey = key
                frameData.append([minExponent], length: MemoryLayout<UInt8>.size)
                self.peripheral.writeValue(frameData as Data,
                                           for: characteristic,
                type: .withResponse)
            } else {
                self.didUpdateConfigurationState(configurationState: ConfigurationState.ErrorUpdatingSlotData)
            }
          }
        } else {
            self.didUpdateConfigurationState(configurationState: ConfigurationState.ErrorUpdatingSlotData)
        }
      }
    } else {
      currentlyUpdatedSlot += 1
      setActiveSlot()
    }
  }
}
