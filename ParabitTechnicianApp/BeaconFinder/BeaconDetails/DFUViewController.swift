//
//  DFUViewController.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/7/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit

class DFUViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //test networking call
        ParabitNetworking.sharedInstance.getFirmwareInfoFor(revision: "01-10-17") { (success) in
            if success{
                print("got the revision firmware")
            }else{
                print("error getting firmware info for revison")
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
