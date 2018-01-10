//
//  ParabitEvents.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 12/20/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import Trackable
import Fabric
import Crashlytics

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
        case USER_TAPPED_NONCONNECTABLE_BEACON
        case USER_CHANGED_ADVERTISING_INTERVAL
        case USER_CHANGED_RADIO_TX_POWER_CHANGED
        case USER_CHECKED_FOR_FIRWARE_UPDATES
        case USER_WENT_TO_START_DFU
        case USER_STARTED_DFU
        case USER_FINISHED_DFU
        case USER_SENT_FEEDBACK
        case USER_OPENED_MENU
    }
    
    enum Firmware : String, Event {
        case FIRMWARE_UPDATE_FOUND
        case UNLOCK_CLOUD_RESPONSE_FAILURE
        case UNLOCK_CODE_NOT_FOUND
        case UNLOCK_WRITE_FAILED

    }
    
    enum Dfu : String, Event {
        case DEBUG_DFU_STARTING
        case DEBUG_DFU_ENABLING
        case DEBUG_DFU_VALIDATING
        case DEBUG_DFU_DISCONNECTING
        case DEBUG_DFU_COMPLETE
        case DEBUG_DFU_ABORTED
        case DEBUG_DFU_ERROR
        case DEBUG_DFU_CONNECTING
        case DEBUG_DFU_END_TRANSFER
        case DEBUG_DFU_START_TRANSFER
    }
    
    enum App : String, Event {
        case APPLICATION_DID_BECOME_ACTIVE
        case SESSION_TIMEOUT
    }
    
    enum Error : String, Event {
        case ERROR_WITH_RETRIEVING_REVISION
        case ERROR_WITH_DFU
        case FIRMWARE_NOT_FOUND
        case ERROR_READING_FIRMWARE
        case LOG_SERVICE_UNAVAILABLE
    }
}

final class EventsLogger {
    // 1
    static let sharedInstance = EventsLogger()
    // 2
    private init() {
        
    }
    
    func logEvent (event:String , info: [String:Any]) {
        //For Timestamp --> guard let mutableDict = info as? NSMutableDictionary else  { print("error converting dict to mutable dict") ; return }
        //aws
        ParabitNetworking.sharedInstance.trackEvent(event: event.description, info: info, completionHandler: {_ in })
        //fabric
        //With timestamp --> Answers.logCustomEvent(withName: event.description, customAttributes: addTimeStampToDict(dict: mutableDict))
        Answers.logCustomEvent(withName: event.description, customAttributes: info)

        
    }
    
    //MARK: Helper methods
    
    func addTimeStampToDict (dict: NSMutableDictionary) -> Dictionary<String,Any> {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2016/10/08 22:31")
        dict.addEntries(from: ["timestamp":someDateTime])
        guard let returnDict = dict as? Dictionary<String,Any> else { return ["":""] }
        return returnDict
    }
    
}




