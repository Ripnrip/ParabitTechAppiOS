//
//  ParabitNetworking.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/19/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import Alamofire

class ParabitNetworking: NSObject {
    static let sharedInstance = ParabitNetworking()
    fileprivate var isInitialized: Bool
    //Used for checking whether Push Notification is enabled in Amazon Pinpoint
    static let remoteNotificationKey = "RemoteNotification"
    fileprivate override init() {
        isInitialized = false
        super.init()
    }
    
    deinit {
        // Should never be called
        print("Mobile Client deinitialized. This should not happen.")
    }
    
    let baseURL = "https://6yomwzar14.execute-api.us-east-1.amazonaws.com/dev/"
    
    //Mark: GET a list of firmware
    func getFirmware(completionHandler:@escaping (Bool) -> ()){
        guard let url = URL(string: "\(baseURL)firmware") else { return }
        print("the url for GET firmware is \(url)")
        
        Alamofire.request(url, method: HTTPMethod.get, parameters: nil, encoding: URLEncoding.default, headers: nil).responseJSON { (dataResponse) in
            
            if dataResponse.error != nil {
                print("there was an error getting the firmware info \(dataResponse.error)")
            }
            guard let request = dataResponse.request, let response = dataResponse.response, let value = dataResponse.value else {return}
            print("the request is ",request)
            print("the response is ",response)
            print("the value is ",value)
            completionHandler(true)
        }
    }
    
    
}
