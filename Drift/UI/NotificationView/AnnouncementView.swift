//
//  NotificationView.swift
//  Drift
//
//  Created by Eoin O'Connell on 26/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit
import SafariServices

class AnnouncementView: CampaignView {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var notificationContainer: UIView!
    @IBOutlet weak var notificationCountlabel: UILabel!
    @IBOutlet weak var bottomButtonColourView: UIView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var openButton: UIButton!
    
    var bottomConstraint: NSLayoutConstraint!
    
    var campaign: Campaign! {
        didSet{
            setUpForCampaign()
        }
    }
    var otherCampaigns: [Campaign] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.clipsToBounds = true
        userImageView.layer.cornerRadius = 4
        userImageView.contentMode = .ScaleAspectFill
        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 5
        notificationContainer.hidden = true
        shadowView.layer.shadowColor = UIColor.blackColor().CGColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowView.layer.shadowOpacity = 0.2
        shadowView.layer.shadowRadius = 2
        shadowView.layer.cornerRadius = 6
    }
    
    func setUpForCampaign() {
        let background = DriftDataStore.sharedInstance.generateBackgroundColor()
        let foreground = DriftDataStore.sharedInstance.generateForegroundColor()

        bottomButtonColourView.backgroundColor = background
        dismissButton.setTitleColor(foreground, forState: .Normal)
        openButton.setTitleColor(foreground, forState: .Normal)
        
        if let announcement = campaign.announcementAttributes {
            titleLabel.text = announcement.title ?? ""
            
            do {
                let htmlStringData = (campaign.bodyText ?? "").dataUsingEncoding(NSUTF8StringEncoding)!
                let options: [String: AnyObject] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                    NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
                    ]
                let attributedHTMLString = try NSMutableAttributedString(data: htmlStringData, options: options, documentAttributes: nil)
                infoLabel.text = attributedHTMLString.string
            } catch {
                infoLabel.text = campaign.bodyText ?? ""
            }
        }

        if let organizerId = campaign.authorId {
            
            APIManager.getUser(organizerId, orgId: DriftDataStore.sharedInstance.embed!.orgId, authToken: DriftDataStore.sharedInstance.auth!.accessToken, completion: { (result) -> () in
                switch result {
                    
                case .Success(let users):
                    if let avatar = users.first?.avatarURL {
                        self.userImageView.af_setImageWithURL(NSURL.init(string:avatar)!)
                    }
                case .Failure(let error):
                    LoggerManager.didRecieveError(error)
                }
            })
        }
        
        if !otherCampaigns.isEmpty {
            notificationCountlabel.text = "\(otherCampaigns.count)"
            notificationCountlabel.layer.cornerRadius = notificationCountlabel.frame.size.width / 2
            notificationCountlabel.clipsToBounds = true
            notificationContainer.layer.cornerRadius = notificationContainer.frame.size.width / 2
            notificationContainer.clipsToBounds = true
            notificationContainer.hidden = false
        }else{
            notificationContainer.hidden = true
        }
    }
    
    override func showOnWindow(window: UIWindow) {
        window.addSubview(self)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        let leading = NSLayoutConstraint(item: self, attribute: .Leading, relatedBy: .Equal, toItem: window, attribute: .Leading, multiplier: 1.0, constant: window.frame.size.width)
        window.addConstraint(leading)
        let trailing = NSLayoutConstraint(item: self, attribute: .Trailing, relatedBy: .Equal, toItem: window, attribute: .Trailing, multiplier: 1.0, constant: window.frame.size.width)
        window.addConstraint(trailing)
        
        var bottomConstant: CGFloat = -15.0
        if TopController.hasTabBar() {
            bottomConstant = -65.0
        }
        
        bottomConstraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: window, attribute: .Bottom, multiplier: 1.0, constant: bottomConstant)
        
        window.addConstraint(bottomConstraint)
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 110.0))
        window.layoutIfNeeded()
        leading.constant = 0
        trailing.constant = 0
        window.setNeedsUpdateConstraints()
        
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            window.layoutIfNeeded()
        }, completion:nil)
    }
    
    
    
    override func hideFromWindow() {

        bottomConstraint.constant = 130
        setNeedsLayout()
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.backgroundColor = UIColor(white: 1, alpha: 0.5)
            self.layoutIfNeeded()
        }, completion: nil)

    }
    
    @IBAction func skipPressed(sender: AnyObject) {
        delegate?.campaignDidFinishWithResponse(self, campaign: campaign, response: .Announcement(.Dismissed))
    }
    
    @IBAction func readPressed(sender: AnyObject) {
        delegate?.campaignDidFinishWithResponse(self, campaign: campaign, response: .Announcement(.Opened))
    }
    
        

}
