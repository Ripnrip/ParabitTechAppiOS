//
//  FeedbackViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 11/24/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit

class FeedbackViewController: UIViewController {

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
    }
    
    func sendFeedback() {
        
    }

    

}
