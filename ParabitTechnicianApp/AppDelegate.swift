//
//  AppDelegate.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/5/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import Fabric
import Crashlytics
import AWSCognito

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var signInViewController: SignInViewController?
    var resetPasswordViewController: FirstTimeLoginViewController?
    var navigationController: UINavigationController?
    var storyboard: UIStoryboard?
    var rememberDeviceCompletionSource: AWSTaskCompletionSource<NSNumber>?

    var newPasswordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>?
    
    var user: AWSCognitoIdentityUser?
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    
    var lastActiveTimeStamp = Date()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Warn user if configuration not updated
        if (CognitoIdentityUserPoolId == "YOUR_USER_POOL_ID") {
            let alertController = UIAlertController(title: "Invalid Configuration",
                                                    message: "Please configure user pool constants in Constants.swift file.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            
            self.window?.rootViewController!.present(alertController, animated: true, completion:  nil)
        }
        //Fabiric
        Fabric.with([Crashlytics.self,AWSCognito.self])
        
        // setup AWS logging
        AWSLogger.default().logLevel = .verbose
        
        // setup service configuration
        let serviceConfiguration = AWSServiceConfiguration(region: CognitoIdentityUserPoolRegion, credentialsProvider: nil)
        
        // create pool configuration
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: CognitoIdentityUserPoolAppClientId,
                                                                        clientSecret: CognitoIdentityUserPoolAppClientSecret,
                                                                        poolId: CognitoIdentityUserPoolId)
        
        // initialize user pool client
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: poolConfiguration, forKey: AWSCognitoUserPoolsSignInProviderKey)
        
        // fetch the user pool client we initialized in above step
        let pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        self.storyboard = UIStoryboard(name: "Main", bundle: nil)
        pool.delegate = self
        
        //We want the technician to log in everytime
        pool.currentUser()?.signOut()
        //_ = ParabitNetworking.sharedInstance

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        //set fromNowTimer if user is signed in
        lastActiveTimeStamp = Date()
        
        print("applicationWillEnterForeground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        let difference = Date().minutes(from: lastActiveTimeStamp)
        print("applicationDidBecomeActive with the last seen time stamp: \(lastActiveTimeStamp) and the currentTimeStamp is: \(Date()) /n the difference in minutes is \(difference)")
        Answers.logCustomEvent(withName: "applicationDidbecomeActive", customAttributes: [:])
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

// MARK:- AWSCognitoIdentityInteractiveAuthenticationDelegate protocol delegate
extension AppDelegate: AWSCognitoIdentityInteractiveAuthenticationDelegate {
    
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        if (self.navigationController == nil) {
            self.navigationController = self.storyboard?.instantiateViewController(withIdentifier: "signinController") as? UINavigationController
        }
        
        if (self.signInViewController == nil) {
            self.signInViewController = self.navigationController?.viewControllers[0] as? SignInViewController
        }
        
        DispatchQueue.main.async {
            self.navigationController!.popToRootViewController(animated: true)
            if (!self.navigationController!.isViewLoaded
                || self.navigationController!.view.window == nil) {
                self.window?.rootViewController?.present(self.navigationController!,
                                                         animated: true,
                                                         completion: nil)
            }
        }
        return self.signInViewController!
    }
    
    // This method is called when we need to reset a password.
    // It will grab the view controller from the storyboard and present it.
    func startNewPasswordRequired() -> AWSCognitoIdentityNewPasswordRequired {
        if (self.resetPasswordViewController == nil) {
            self.resetPasswordViewController = self.storyboard?.instantiateViewController(withIdentifier: "FirstSignInViewController") as? FirstTimeLoginViewController
        }
        DispatchQueue.main.async {
            if(self.resetPasswordViewController!.isViewLoaded || self.resetPasswordViewController!.view.window == nil) {
               // self.navigationController?.present(self.resetPasswordViewController!, animated: true, completion: nil)

                self.window?.rootViewController?.present(self.resetPasswordViewController!,
                                                         animated: true,
                                                         completion: nil)
            }
        }
        guard let controller = self.resetPasswordViewController else { return UIViewController()  as! AWSCognitoIdentityNewPasswordRequired }
        return controller
    }
    
    
    func startRememberDevice() -> AWSCognitoIdentityRememberDevice {
        return self
    }
}



// MARK:- AWSCognitoIdentityRememberDevice protocol delegate
extension AppDelegate: AWSCognitoIdentityRememberDevice {
    
    func getRememberDevice(_ rememberDeviceCompletionSource: AWSTaskCompletionSource<NSNumber>) {
        self.rememberDeviceCompletionSource = rememberDeviceCompletionSource
        DispatchQueue.main.async {
            // dismiss the view controller being present before asking to remember device
            self.window?.rootViewController!.presentedViewController?.dismiss(animated: true, completion: nil)
            let alertController = UIAlertController(title: "Remember Device",
                                                    message: "Do you want to remember this device?.",
                                                    preferredStyle: .actionSheet)
            
            let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                self.rememberDeviceCompletionSource?.set(result: true)
            })
            let noAction = UIAlertAction(title: "No", style: .default, handler: { (action) in
                self.rememberDeviceCompletionSource?.set(result: false)
            })
            alertController.addAction(yesAction)
            alertController.addAction(noAction)
            
            self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func didCompleteStepWithError(_ error: Error?) {
        DispatchQueue.main.async {
            if let error = error as? NSError {
                let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                DispatchQueue.main.async {
                    self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
            }else{
                print("some error NOT ")
                
            }
        }
    }
}
