//
//  LoginViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/5/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import AWSAuthUI
import AWSUserPoolsSignIn

class LoginViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //presentAuthUIViewController()

    }
    func presentAuthUIViewController() {
        let config = AWSAuthUIConfiguration()
        config.enableUserPoolsUI = true
        
        // you can use properties like logoImage, backgroundColor to customize screen
        // config.canCancel = false // prevent end user dismissal of the sign in screen
        
        // you should have a navigation controller for your view controller
        // the sign in screen is presented using the navigation controller
        
        AWSAuthUIViewController.presentViewController(
            with: navigationController!,  // put your navigation controller here
            configuration: config,
            completionHandler: {(
                _ signInProvider: AWSSignInProvider, _ error: Error?) -> Void in
                if error == nil {
                    DispatchQueue.main.async(execute: {() -> Void in
                        // handle successful callback here,
                        // e.g. pop up to show successful sign in
                    })
                    
                }
                else {
                    // end user faced error while logging in,
                    // take any required action here
                    print("there was an error signing in \(error)")
                }
        })
    }
    
    

}
