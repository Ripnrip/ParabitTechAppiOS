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
import SwiftSpinner

class ParabitNetworking: NSObject {
    static let sharedInstance = ParabitNetworking()
    fileprivate var isInitialized: Bool
    //Used for checking whether Push Notification is enabled in Amazon Pinpoint
    static let remoteNotificationKey = "RemoteNotification"
    
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    
    var userAttributes : [AWSCognitoIdentityProviderAttributeType]?
    
    var firmwareAPIVersion: AWSCognitoIdentityProviderAttributeType?
    var firmwareAPIKey: AWSCognitoIdentityProviderAttributeType?
    var firmwareAPIURL: AWSCognitoIdentityProviderAttributeType?
    
    var feedbackAPIURL: AWSCognitoIdentityProviderAttributeType?
    var feedbackAPIKey: AWSCognitoIdentityProviderAttributeType?
    
    var beaconAPIRUL: AWSCognitoIdentityProviderAttributeType?
    var beaconAPIKey: AWSCognitoIdentityProviderAttributeType?
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var timer:Timer!
    var counter = 0
    
    var baseURL = ""//"https://api.parabit.com/dev-firmware/"//https://6yomwzar14.execute-api.us-east-1.amazonaws.com/dev/"

    
    fileprivate override init() {
        isInitialized = false
        super.init()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
        }
        //self.getAuthenticationKeys()
        let nc = NotificationCenter.default // Note that default is now a property, not a method call
        nc.addObserver(forName:Notification.Name(rawValue:"userSignedIn"),
                       object:nil, queue:nil,
                       using:catchNotification)
        
    }
    
    deinit {
        // Should never be called
        print("Mobile Client deinitialized. This should not happen.")
    }
    
    
    //MARK: GET a list of firmware
    func getFirmware(completionHandler:@escaping (Bool) -> ()){
        guard let url = URL(string: "\(baseURL)firmware") else { return }
        print("the url for GET firmware is \(url)")
        
        Alamofire.request(url, method: HTTPMethod.get, parameters: nil, encoding: URLEncoding.default, headers: nil).responseJSON { (dataResponse) in
            
            if dataResponse.error != nil {
                print("there was an error getting the firmware info \(dataResponse.error)")
                completionHandler(false)
            }
            guard let request = dataResponse.request, let response = dataResponse.response, let value = dataResponse.value else { return }
            print("the request is ",request)
            print("the response is ",response)
            print("the value is ",value)
            completionHandler(true)
        }
    }
    
    //MARK: GET a firmware check
    func getFirmwareInfoFor(revision:String, completionHandler:@escaping (FirmwareInfo?) -> ()){
        guard let url = URL(string: "\(baseURL)firmware/info"), let apiKey = firmwareAPIKey?.value else { return }
        print("the url for the GET firmware info is \(url)")

        
        let headers:[String : String] = ["x-api-key" : apiKey]
        Alamofire.request(url, method: HTTPMethod.get, parameters: ["revision":revision], encoding: URLEncoding.default, headers: headers).responseJSON { (dataResponse) in
            
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
            } else {
                //firmware is not up-to-date
                completionHandler(firmware)
            }
        }
    }
    
    //Mark: POST a unlock code to get an unlock token
    func getUnlockToken(currentFirmwareRevision:String, unlockChallenge:String, completionHandler:@escaping (String?) -> ()) {
        guard let url = URL(string: "\(baseURL)firmware/unlock"),
        let apiKey = firmwareAPIKey?.value
        else { return }
        print("the url for the POST firmware unlcok is \(url)")
        
        let headers:[String : String] = ["x-api-key" : apiKey]
        let parameters:[String : Any] = ["firmware_revision":currentFirmwareRevision,"challenge":unlockChallenge]

        Alamofire.request(url, method: HTTPMethod.post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (dataResponse) in
            
            if dataResponse.error != nil || dataResponse.response?.statusCode != 200 {
                print("there was an error getting the firmware unlock for revision \(dataResponse.error)")
                completionHandler(nil)
                //SwiftSpinner.hide()
                return
            }
            guard let request = dataResponse.request, let response = dataResponse.response, let value = dataResponse.value, let dict = value as? [String:Any], let unlockResponse = dict["unlock_response"] as? String
                else {return}
            completionHandler(unlockResponse)
                }
    }
    
    //Mark: POST Feedback about the app
    func submitFeedback(feedback:String, context:String?, completionHandler:@escaping (Bool) -> ()) {
        //category general
        guard var url = feedbackAPIURL?.value,
            let apiKey = feedbackAPIKey?.value,
            let username = user?.username
            else { return }
        
        url = "\(url)feedback"
        print("the url for the POST feedback is \(url)")
        let headers:[String : String] = ["x-api-key" : apiKey]
        let parameters:[String : Any] = ["username":username,"feedback":feedback,"context":"","category":"general"]
        
        Alamofire.request(url, method: HTTPMethod.post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (dataResponse) in
            
            if dataResponse.error != nil || dataResponse.response?.statusCode != 200 {
                print("there was an error getting the firmware unlock for revision \(dataResponse.error)")
                completionHandler(false)
                SwiftSpinner.hide()
                return
            }
            guard let request = dataResponse.request, let response = dataResponse.response, let value = dataResponse.value, let dict = value as? [String:Any]
                else {return}
            print("the response from posting feedback is \(response)")
            completionHandler(true)
        }
    }
    
    //Mark: POST Problem about the app
    func submitProblem(problem:String, context:String?, completionHandler:@escaping (Bool) -> ()) {
        //category problem
        guard var url = feedbackAPIURL?.value,
            let apiKey = feedbackAPIKey?.value,
            let username = user?.username
            else { return }
        
        url = "\(url)feedback"
        print("the url for the POST problem is \(url)")
        let headers:[String : String] = ["x-api-key" : apiKey]
        let parameters:[String : Any] = ["username":username,"feedback":problem,"context":"","category":"problem"]
        
        Alamofire.request(url, method: HTTPMethod.post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (dataResponse) in
            
            if dataResponse.error != nil || dataResponse.response?.statusCode != 200 {
                print("there was an error getting the firmware unlock for revision \(dataResponse.error)")
                completionHandler(false)
                SwiftSpinner.hide()
                return
            }
            guard let request = dataResponse.request, let response = dataResponse.response, let value = dataResponse.value, let dict = value as? [String:Any]
                else {return}
            print("the response from posting problem is \(response)")
            completionHandler(true)
        }
        
    }
    
    //Mark: Helper for authentication
    func getAuthenticationKeys() {
        self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async(execute: {
                self.response = task.result
                print("the response for getting user info in the ParabitNetworkingClass is \(self.response?.userAttributes)")
                
                guard let userAttributes = self.response?.userAttributes else { return }
                self.userAttributes = userAttributes
                
                userAttributes.forEach({ (attribute) in
                    switch attribute.name! {
                        case "custom:firmware-api-key":
                            self.firmwareAPIKey = attribute
                        case "custom:firmware-api-url":
                            self.firmwareAPIURL = attribute
                            guard let firmwareURL = self.firmwareAPIURL?.value else { print("error unwrapping firmwareURL"); break }
                            self.baseURL = firmwareURL
                        case "custom:firmware-api-version":
                            self.firmwareAPIVersion = attribute
                        case "custom:feedback-api-url":
                            self.feedbackAPIURL = attribute
                        case "custom:feedback-api-key":
                            self.feedbackAPIKey = attribute
                        case "custom:beacon-api-key":
                            self.beaconAPIRUL = attribute
                        case "custom:beacon-api-url":
                            self.beaconAPIKey = attribute
                        default:
                        print("printing value for attribute \(attribute)")
                    }
                })

            })
            return nil
        }
    }
    
    //Mark: Notification
    func catchNotification(notification:Notification) -> Void {
        print("Catch notification")

        getAuthenticationKeys()

        guard let userInfo = notification.userInfo,
            let message  = userInfo["message"] as? String,
            let date     = userInfo["date"]    as? Date else {
                print("No userInfo found in notification")
                return
        }

    }
    
    //Mark: Helper for session timer
    func startSessionTimer(){
        print("Started Session Timer")
        let oneHour = Int(60 * 60)
        let halfHour = Int(60 * 30)
        let fiveMinutes = Int(60 * 5)
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(halfHour), target: self, selector: #selector(sessionTimeOut), userInfo: nil, repeats: true)
    }
    
    func sessionTimeOut(){
        print("Should End Session at time \(timer)")
        EventsLogger.sharedInstance.logEvent(event: Events.App.SESSION_TIMEOUT , info: ["user":self.user?.username ?? "","time":timer])
        user?.signOut()
        self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async(execute: {
                self.response = task.result
            })
            return nil
        }
    }
    
}
