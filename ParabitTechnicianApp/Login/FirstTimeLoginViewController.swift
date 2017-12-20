//
//  FirstTimeLoginViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 12/5/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import Fabric
import Crashlytics

class FirstTimeLoginViewController: UIViewController {
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    var pool: AWSCognitoIdentityUserPool?
    var proposedPassword = ""
    
    var newPasswordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>?

    override func viewWillAppear(_ animated: Bool) {
        
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func updatePassword(_ sender: Any) {
        if (self.passwordTextField.text == self.confirmPasswordTextField.text && self.confirmPasswordTextField.text?.count != 0)  {
            
            
            let requiredAttributes = Set<String>()
            let details = AWSCognitoIdentityNewPasswordRequiredDetails(proposedPassword: self.confirmPasswordTextField.text!, userAttributes: [:])
            proposedPassword = self.confirmPasswordTextField.text!

            self.newPasswordAuthenticationCompletion?.set(result: details)

            self.newPasswordAuthenticationCompletion?.task.continueOnSuccessWith(block: { (task) -> Any? in
                print("the task is \(task) /n with result \(task.result!)")
                
            })
            
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

extension FirstTimeLoginViewController: AWSCognitoIdentityInteractiveAuthenticationDelegate{

    func startNewPasswordRequired() -> AWSCognitoIdentityNewPasswordRequired {
        return self
    }

}

extension FirstTimeLoginViewController: AWSCognitoIdentityNewPasswordRequired {
    func getNewPasswordDetails(_ newPasswordRequiredInput: AWSCognitoIdentityNewPasswordRequiredInput, newPasswordRequiredCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>) {
        self.newPasswordAuthenticationCompletion = newPasswordRequiredCompletionSource
    }

    func didCompleteNewPasswordStepWithError(_ error: Error?) {
        DispatchQueue.main.async {
            if let error = error as? NSError {
                let alertController = UIAlertController(title: "Log In Error",
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                alertController.addAction(retryAction)

                self.present(alertController, animated: true, completion:  nil)
            }else{
                //did complete login success
                //TODO: Show alert saying password has been set

                print("did complete new password setup, should dismiss view now, or check if they are logged in ")
                //self.dismiss(animated: true, completion: nil)
                //self.navigationController?.popViewController(animated: true)
                guard let user = self.pool?.currentUser() else { return }
                Answers.logCustomEvent(withName: "USER_SETUP_FIRST_PASSWORD", customAttributes: ["user":user])
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}



