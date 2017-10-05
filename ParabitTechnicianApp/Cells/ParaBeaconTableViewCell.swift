//
//  ParaBeaconTableViewCell.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/5/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import UIKit

class ParaBeaconTableViewCell: UITableViewCell {

    @IBOutlet weak var statusBubbleImageView: UIImageView!
    @IBOutlet weak var beaconNameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
