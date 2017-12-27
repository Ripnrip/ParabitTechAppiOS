//
//  ParabitEvents.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 12/20/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import Trackable

enum Events {
    enum User : String, Event {
        case USER_HIT_REFRESH
        case USER_SIGNED_IN
        case USER_NEEDS_TO_SETUP_FIRST_TIME_PASSWORD
        case USER_RESET_PASSWORD
        case USER_FORGOT_PASSWORD
        case USER_SETUP_FIRST_PASSWORD
        case USER_TAPPED_PROFILE
        case USER_SIGNED_OUT
        case USER_TAPPED_FEEDBACK
        case USER_TAPPED_ABOUT
        case USER_DISCONNECTED_FROM_BEACON
        case USER_OPENED_BEACON_CONFIGURATION
        case USER_TAPPED_DISCONNECT
        case USER_TAPPED_CONNECT
        case USER_CHANGED_ADVERTISING_INTERVAL
        case USER_CHANGED_RADIO_TX_POWER_CHANGED
        case USER_CHECKED_FOR_FIRWARE_UPDATES
        case FIRMWARE_UPDATE_FOUND
        case USER_WENT_TO_START_DFU
        case USER_STARTED_DFU
        case USER_FINISHED_DFU
        case USER_SENT_FEEDBACK
    }
    
    enum App : String, Event {
        case APPLICATION_DID_BECOME_ACTIVE
    }
    
    enum Error : String, Event {
        case ERROR_WITH_RETRIEVING_REVISION
        case ERROR_WITH_DFU

    }
    
    func logEvent (event:Event , info: [String:String]) {
        //aws
        
        //fabric
        
        //any other
        
    }
    
}
