//
//  ParabitNetworking.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/19/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import Alamofire
import AWSCognitoIdentityProvider


class ParabitNetworking: NSObject {
    static let sharedInstance = ParabitNetworking()
    fileprivate var isInitialized: Bool
    //Used for checking whether Push Notification is enabled in Amazon Pinpoint
    static let remoteNotificationKey = "RemoteNotification"
    
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    
    var firmwareAPIVersion:AWSCognitoIdentityProviderAttributeType?
    var firmwareAPIKey:AWSCognitoIdentityProviderAttributeType?
    var firmwareAPIURL: AWSCognitoIdentityProviderAttributeType?
    
    fileprivate override init() {
        isInitialized = false
        super.init()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
        }
        self.getAuthenticationKeys()
        
    }
    
    deinit {
        // Should never be called
        print("Mobile Client deinitialized. This should not happen.")
    }
    

    
    let baseURL = "https://api.parabit.com/dev-firmware/"//https://6yomwzar14.execute-api.us-east-1.amazonaws.com/dev/"
    
    let apiKey1 = " "
    let apiKey2 = " "
    
    
    //MARK: GET a list of firmware
    func getFirmware(completionHandler:@escaping (Bool) -> ()){
        guard let url = URL(string: "\(baseURL)firmware") else { return }
        print("the url for GET firmware is \(url)")
        
        Alamofire.request(url, method: HTTPMethod.get, parameters: nil, encoding: URLEncoding.default, headers: nil).responseJSON { (dataResponse) in
            
            if dataResponse.error != nil {
                print("there was an error getting the firmware info \(dataResponse.error)")
                completionHandler(false)
            }
            guard let request = dataResponse.request, let response = dataResponse.response, let value = dataResponse.value else {return}
            print("the request is ",request)
            print("the response is ",response)
            print("the value is ",value)
            completionHandler(true)
        }
    }
    
    //MARK: GET a firmware check
    func getFirmwareInfoFor(revision:String, completionHandler:@escaping (FirmwareInfo?) -> ()){
        guard let url = URL(string: "\(baseURL)firmware/info") else { return }
        print("the url for the GET firmware info is \(url)")
        
        Alamofire.request(url, method: HTTPMethod.get, parameters: ["revision":revision], encoding: URLEncoding.default, headers: nil).responseJSON { (dataResponse) in
            
            if dataResponse.error != nil || dataResponse.response?.statusCode != 200 {
                print("there was an error getting the firmware info for revision \(dataResponse.error)")
                completionHandler(nil)
                return
            }
            guard let request = dataResponse.request, let response = dataResponse.response, let value = dataResponse.value else {return}
            print("the request is ",request)
            print("the response is ",response)
            print("the value is ",value)
            
            guard let json = value as? [String:Any],
            let current = json["current"] as? [String:Any],
            let latest = json["latest"] as? [String:Any],
            let latestURL = json["latestURL"] as? String else { return }
            print("the current is \(current) and the latest is \(latest) with url \(latestURL)")
            
            let currentFirmware = Firmware(createdAt: (current["createdAt"] as! Int), id: current["id"] as! String, revision: current["revision"] as! String, updatedAt: current["updatedAt"] as! Int, unlockcode: current["unlock_code"] as! String)
            let latestFirmware = Firmware(createdAt: (latest["createdAt"] as! Int), id: latest["id"] as! String, revision: latest["revision"] as! String, updatedAt: latest["updatedAt"] as! Int, unlockcode: latest["unlock_code"] as! String)
            let firmware = FirmwareInfo(currentFirmware: currentFirmware, latestFirmware: latestFirmware, latestURL: URL(string: latestURL)!)
            
            if currentFirmware.revision == latestFirmware.revision {
                //firmware is up-to-date
                completionHandler(nil)
                return
            }
        }
    }
    
    func getUnlockToken(currentFirmwareRevision:String, unlockChallenge:String, completionHandler:@escaping (Bool) -> ()) {
        guard let url = URL(string: "\(baseURL)firmware/unlock") else { return }
        print("the url for the POST firmware unlcok is \(url)")
        
        Alamofire.request(url, method: HTTPMethod.post, parameters: ["revision":currentFirmwareRevision,"":unlockChallenge], encoding: URLEncoding.default, headers: nil).responseJSON { (dataResponse) in
            
            if dataResponse.error != nil || dataResponse.response?.statusCode != 200 {
                print("there was an error getting the firmware unlock for revision \(dataResponse.error)")
                completionHandler(false)
                return
            }
            guard let request = dataResponse.request, let response = dataResponse.response, let value = dataResponse.value else {return}
            print("the request is ",request)
            print("the response is ",response)
            print("the value is ",value)
            
            
        }
    }
    
    //Mark: Helper for authentication
    
    func getAuthenticationKeys() {
        self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async(execute: {
                self.response = task.result
                print("the response for getting user info in the ParabitNetworkingClass is \(self.response?.userAttributes)")
                
                guard let userAttributes = self.response?.userAttributes else { return }
                self.firmwareAPIVersion = userAttributes[2]
                self.firmwareAPIKey = userAttributes[3]
                self.firmwareAPIURL = userAttributes[4] 
                
            })
            return nil
        }
    }
    
}
