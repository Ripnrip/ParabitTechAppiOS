//
//  Firmware.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/30/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation

struct Firmware:Codable {
    let createdAt: Int
    let id: String
    let revision: String
    let updatedAt: Int
    let unlockcode: String
}

struct FirmwareInfo {
    let currentFirmware : Firmware
    let latestFirmware : Firmware
    let latestURL : URL
}
