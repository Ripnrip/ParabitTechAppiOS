//
//  Firmware.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/30/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation


enum FirmwareType{
    case current, new
}
struct Firmware {
    let createdAt: Int
    let id: String
    let revision: String
    let updatedAt: Date
    let unlockcode: String
}
