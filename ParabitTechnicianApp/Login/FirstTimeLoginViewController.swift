//
//  FirstTimeLoginViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 12/5/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider


class FirstTimeLoginViewController: UIViewController, AWSCognitoIdentityNewPasswordRequired {
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func updatePassword(_ sender: Any) {
        if (self.passwordTextField.text == self.confirmPasswordTextField.text)  {
            var requiredAttributes = Set<String>()
            let authDetails = AWSCognitoIdentityNewPasswordRequiredInput(userAttributes: [:], requiredAttributes: requiredAttributes)
            var newPasswordRequiredDetails = AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>()
            self.getNewPasswordDetails(authDetails, newPasswordRequiredCompletionSource: newPasswordRequiredDetails)
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
    
    func getNewPasswordDetails(_ newPasswordRequiredInput: AWSCognitoIdentityNewPasswordRequiredInput, newPasswordRequiredCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>) {
        //
        
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
                    print("did complete new password setup, should dismiss view now, or check if they are logged in ")
                }
        }
    }
    

}
