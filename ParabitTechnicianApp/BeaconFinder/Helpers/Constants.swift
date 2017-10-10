//
//  Constants.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/10/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import CoreBluetooth

enum LockState: UInt8 {
    case Locked = 0
    case Unlocked
    case UnlockedPreventAutolock
    case Unknown = 255
}

enum CharacteristicID {
    case capabilities
    case activeSlot
    case advertisingInterval
    case radioTxPower
    case advertisedTxPower
    case lockState
    case unlock
    case publicECDHKey
    case EIDIdentityKey
    case ADVSlotData
    case factoryReset
    case remainConnectable
    
    var UUID: CBUUID {
        switch self {
        case .capabilities:
            return CBUUID(string: "A3C87501-8ED3-4BDF-8A39-A01BEBEDE295")
        case .activeSlot:
            return CBUUID(string: "A3C87502-8ED3-4BDF-8A39-A01BEBEDE295")
        case .advertisingInterval:
            return CBUUID(string: "A3C87503-8ED3-4BDF-8A39-A01BEBEDE295")
        case .radioTxPower:
            return CBUUID(string: "A3C87504-8ED3-4BDF-8A39-A01BEBEDE295")
        case .advertisedTxPower:
            return CBUUID(string: "A3C87505-8ED3-4BDF-8A39-A01BEBEDE295")
        case .lockState:
            return CBUUID(string: "A3C87506-8ED3-4BDF-8A39-A01BEBEDE295")
        case .unlock:
            return CBUUID(string: "A3C87507-8ED3-4BDF-8A39-A01BEBEDE295")
        case .publicECDHKey:
            return CBUUID(string: "A3C87508-8ED3-4BDF-8A39-A01BEBEDE295")
        case .EIDIdentityKey:
            return CBUUID(string: "A3C87509-8ED3-4BDF-8A39-A01BEBEDE295")
        case .ADVSlotData:
            return CBUUID(string: "A3C8750A-8ED3-4BDF-8A39-A01BEBEDE295")
        case .factoryReset:
            return CBUUID(string: "A3C8750B-8ED3-4BDF-8A39-A01BEBEDE295")
        case .remainConnectable:
            return CBUUID(string: "A3C8750C-8ED3-4BDF-8A39-A01BEBEDE295")
        }
    }
}
