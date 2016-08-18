//
//  ConversationListTableViewCell.swift
//  Drift
//
//  Created by Brian McDonald on 26/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit

class ConversationListTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var updatedAtLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
        messageLabel.textColor = ColorPalette.GrayColor
        updatedAtLabel.textColor = ColorPalette.GrayColor
        avatarImageView.layer.masksToBounds = true
        avatarImageView.contentMode = .ScaleAspectFill
        avatarImageView.layer.cornerRadius = 3
    }
}
