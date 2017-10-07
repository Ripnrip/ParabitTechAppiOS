//
//  Parabeacon.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/7/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import UIKit

class Parabeacon {
    var name:String? = nil
    var description:String? = nil
    var address:String = ""
    var nameSpace:String = ""
    var instance:String = ""
    var rssi:Int? = nil
    var isConfigurable:Bool = false
    var slotsAvailable:Int? = nil
    var eidSlotsAvailable:Int? = nil
    var advInterval:Int? = nil
    var isRegistered:Bool = false
    
    init(name:String, description:String?, address:String, nameSpace:String, instance:String, rssi:Int?, isConfigurable:Bool, slotsAvailable:Int?, eidSlotsAvailable:Int?, advInterval:Int?, isRegistered:Bool) {
        self.name = name
        self.description = description ?? "nil"
        self.address = address
        self.nameSpace = name
        self.instance = instance
        self.rssi = rssi ?? 0
        self.isConfigurable = isConfigurable
        self.slotsAvailable = slotsAvailable ?? 1
        self.eidSlotsAvailable = eidSlotsAvailable ?? 1
        self.advInterval = advInterval ?? 0
        self.isRegistered = isRegistered
    }
    
}
