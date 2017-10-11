//
//  RegistrationViewController+TableView.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/7/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import UIKit

extension RegistrationViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "registerCell\(indexPath.row)"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) else {return UITableViewCell()}
        return cell
    }
    
    
}
