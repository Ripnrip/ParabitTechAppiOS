//
//  FeedbackViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 11/24/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import BPStatusBarAlert
import Crashlytics
import Fabric
import AWSCognitoIdentityProvider

class FeedbackViewController: UIViewController {
    @IBOutlet weak var feedbackTextView: UITextView!
    
    var user:AWSCognitoIdentityUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "Feedback"
        
        let btn1 = UIButton(type: .custom)
        btn1.setImage(UIImage(named: "sendIcon"), for: .normal)
        btn1.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn1.addTarget(self, action: #selector(FeedbackViewController.sendFeedback), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: btn1)
        
        self.navigationItem.setRightBarButton(item1, animated: true)
        
        let pool = AWSCognitoIdentityUserPool(forKey:AWSCognitoUserPoolsSignInProviderKey)
        user = pool.currentUser()
        
        if ParabitNetworking.sharedInstance.userAttributes == nil {
            ParabitNetworking.sharedInstance.getAuthenticationKeys()
        }
    }
    
    func sendFeedback() {
        guard let user = self.user else { return }
        Answers.logCustomEvent(withName: "USER_SENT_FEEDBACK", customAttributes: ["user":user,"feedback":feedbackTextView.text])
        
        ParabitNetworking.sharedInstance.submitFeedback(feedback: feedbackTextView.text, context: "") { (success) in
            if success {
                print("succesfully send feedback")
                
                BPStatusBarAlert(duration: 0.1, delay: 2, position: .statusBar) // customize duration, delay and position
                    .message(message: "Successfully sent feedback, thank you!")
                    .messageColor(color: .white)
                    .bgColor(color: .green)
                    .completion { self.navigationController?.popViewController(animated: true) }
                    .show()
            }else{
                print("error in sending feedback")
                
                BPStatusBarAlert(duration: 0.1, delay: 2, position: .statusBar) // customize duration, delay and position
                    .message(message: "Error sending feedback, please try again later.")
                    .messageColor(color: .white)
                    .bgColor(color: .red)
                    .completion { print("")
                    }
                    .show()
            }
        }
    }

    

}
