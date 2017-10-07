//
//  UIDViewController+PickerView.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/7/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import UIKit

extension UIDViewController : UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "UID"
    }

}

