//
//  ReportProblemViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 1/16/18.
//  Copyright © 2018 Gurinder Singh. All rights reserved.
//

import UIKit
import BPStatusBarAlert
import Crashlytics
import Fabric
import AWSCognitoIdentityProvider

class ReportProblemViewController: UIViewController {

    @IBOutlet weak var feedbackTextView: UITextView!
    
    var user:AWSCognitoIdentityUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Report Problem"
        
        let btn1 = UIButton(type: .custom)
        btn1.setImage(UIImage(named: "sendIcon"), for: .normal)
        btn1.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn1.addTarget(self, action: #selector(ReportProblemViewController.reportProblem), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: btn1)
        
        self.navigationItem.setRightBarButton(item1, animated: true)
        
        let pool = AWSCognitoIdentityUserPool(forKey:AWSCognitoUserPoolsSignInProviderKey)
        user = pool.currentUser()
        
        if ParabitNetworking.sharedInstance.userAttributes == nil {
            ParabitNetworking.sharedInstance.getAuthenticationKeys()
        }
        
        
    }

    func reportProblem() {
        guard let user = self.user else { return }
        Answers.logCustomEvent(withName: "USER_SENT_PROBLEM", customAttributes: ["user":user,"problem":"sample Problem"])
        ParabitNetworking.sharedInstance.submitProblem(problem: "Sample Problem", context: "") { (success) in
            if success {
                print("succesfully send problem")
                
                BPStatusBarAlert(duration: 0.1, delay: 2, position: .statusBar) // customize duration, delay and position
                    .message(message: "Successfully sent problem, thank you!")
                    .messageColor(color: .white)
                    .bgColor(color: .green)
                    .completion { self.navigationController?.popViewController(animated: true) }
                    .show()
            }else{
                print("error in sending feedback")
                
                BPStatusBarAlert(duration: 0.1, delay: 2, position: .statusBar) // customize duration, delay and position
                    .message(message: "Error sending problem, please try again later.")
                    .messageColor(color: .white)
                    .bgColor(color: .red)
                    .completion { print("")
                    }
                    .show()
            }
        }
        //ParabitNetworking.sharedInstance.submitFeedback(feedback: feedbackTextView.text, context: "") { (success) in
    }
    

}
