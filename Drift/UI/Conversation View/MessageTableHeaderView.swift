//
//  MessageTableHeaderView.swift
//  Conversations
//
//  Created by Adam Gammell on 12/05/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit

class MessageTableHeaderView: UIView {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var bottomFade: UIView!
    let grad = CAGradientLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.textColor = DriftDataStore.secondaryFontColor
        backgroundColor = UIColor.whiteColor()
        
        grad.frame = bottomFade.bounds
        grad.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().colorWithAlphaComponent(0.02).CGColor]
        bottomFade.layer.addSublayer(grad)
    }

}