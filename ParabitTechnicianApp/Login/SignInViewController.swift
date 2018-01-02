//
// Copyright 2014-2017 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License").
// You may not use this file except in compliance with the
// License. A copy of the License is located at
//
//     http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, express or implied. See the License
// for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import AWSCognitoIdentityProvider
import Fabric
import Crashlytics
import Trackable

class SignInViewController: UIViewController, TrackableClass {
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var versionLabel: UILabel!
    
    
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    var usernameText: String?
    var rememberDeviceCompletionSource: AWSTaskCompletionSource<NSNumber>?

    var userRequiresNewPassword = false
    
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.password.text = nil
        self.username.text = usernameText
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        userRequiresNewPassword = false
    }
    
    override func viewDidLoad() {
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        //self.pool?.delegate = self
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
        }
        self.refresh()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("hideKeyboard"))
        tapGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(tapGesture)

        guard let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return }
        versionLabel.text = "Version: \(versionNumber)"
        
        //Temp leaving out because of new design that moves view up
//        NotificationCenter.default.addObserver(self, selector: #selector(SignInViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(SignInViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func hideKeyboard() {
        username.endEditing(true)
        password.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= 70//keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += 70//keyboardSize.height
            }
        }
    }
    
    func refresh() {
        self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async(execute: {
                self.response = task.result
                //self.title = self.user?.username
                self.username.text = self.user?.username
            })
            return nil
        }
    }
    
    @IBAction func signInPressed(_ sender: AnyObject) {
        EventsLogger.sharedInstance.logEvent(event: Events.User.USER_SIGNED_IN, info: nil)
        if (self.username.text?.count != 0 && self.password.text?.count != 0) || false {
            let authDetails = AWSCognitoIdentityPasswordAuthenticationDetails(username: self.username.text!, password: self.password.text! )
            self.passwordAuthenticationCompletion?.set(result: authDetails)
            print("did set auth details.")
        } else {
            let alertController = UIAlertController(title: "Missing information",
                                                    message: "Please enter a valid user name and password",
                                                    preferredStyle: .alert)
            let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
            alertController.addAction(retryAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
}


extension SignInViewController: AWSCognitoIdentityInteractiveAuthenticationDelegate{

    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        return self
    }

    func startNewPasswordRequired() -> AWSCognitoIdentityNewPasswordRequired {
        return self
    }

}

extension SignInViewController: AWSCognitoIdentityNewPasswordRequired {
    func getNewPasswordDetails(_ newPasswordRequiredInput: AWSCognitoIdentityNewPasswordRequiredInput, newPasswordRequiredCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>) {
        //Show Change Password Screen here for first-time user
        guard let user = self.user else { return }
        
        EventsLogger.sharedInstance.logEvent(event: Events.User.USER_NEEDS_TO_SETUP_FIRST_TIME_PASSWORD, info: ["user":user])

        userRequiresNewPassword = true
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "FirstSignInViewController")
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func didCompleteNewPasswordStepWithError(_ error: Error?) {
        print("the error is \(error)")
        
    }
    
    
}


extension SignInViewController: AWSCognitoIdentityPasswordAuthentication {
    
    public func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        self.passwordAuthenticationCompletion = passwordAuthenticationCompletionSource
        DispatchQueue.main.async {
            if (self.usernameText == nil && self.username != nil) {
                self.usernameText = authenticationInput.lastKnownUsername
                self.username.text = self.user?.username
                //log user fabric
                self.logUser()
                
            }
        }
    }
    
    func logUser() {
       guard let userName = self.user?.username else { return }
       Crashlytics.sharedInstance().setUserName(userName)
       Crashlytics.sharedInstance().setUserEmail(userName)
       Crashlytics.sharedInstance().setUserIdentifier(self.user?.deviceId)
       print("set the fabric/crashlytics info")
    }
    
    public func didCompleteStepWithError(_ error: Error?) {
        DispatchQueue.main.async {
            if let error = error as? NSError {
                let alertController = UIAlertController(title: "Log In Error",
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                alertController.addAction(retryAction)
                
                self.present(alertController, animated: true, completion:  nil)
            } else {
                _ = ParabitNetworking.sharedInstance
                ParabitNetworking.sharedInstance.startSessionTimer()
                //ParabitNetworking.sharedInstance.getAuthenticationKeys()
                print("the user's status is \(self.user!.confirmedStatus)")
                self.username.text = nil
                //determine if user needs to go to new password set screen
                self.userRequiresNewPassword ? nil : self.dismiss(animated: true, completion: nil)
                
                //protocol to send delegate after success sign in
                //notify listeners
                let nc = NotificationCenter.default
                nc.post(name:Notification.Name(rawValue:"userSignedIn"),
                        object: nil,
                        userInfo: ["message":"Hello there!", "date":Date()])
                
            }
        }
    }
}






