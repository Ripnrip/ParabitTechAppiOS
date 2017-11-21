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
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var nameSpaceLabel: UILabel!
    @IBOutlet weak var instanceLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    @IBOutlet weak var configurableStatusLabel: UILabel!
    @IBOutlet weak var registeredLabel: UILabel!
    @IBOutlet weak var disconnectButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
