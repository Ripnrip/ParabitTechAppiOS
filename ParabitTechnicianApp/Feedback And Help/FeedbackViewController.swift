//
//  FeedbackViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 11/24/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit
import CRNotifications
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
        
        self.feedbackTextView.delegate = self
        
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
                self.navigationController?.popViewController(animated: true)
                CRNotifications.showNotification(type: .success, title: "Alert", message: "Successfully sent feedback, thank you!", dismissDelay: 2.5)

            }else{
                print("error in sending feedback")
                self.navigationController?.popViewController(animated: true)
                CRNotifications.showNotification(type: .error, title: "Alert", message: "Error sending feedback, please try again later.", dismissDelay: 2.5)

            }
        }
    }
    
}

extension FeedbackViewController : UITextViewDelegate {
 
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = nil
        textView.textColor = UIColor.black
    }
    
}

