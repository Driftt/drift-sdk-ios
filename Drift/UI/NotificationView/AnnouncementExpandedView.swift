//
//  AnnouncementExpandedView.swift
//  Drift
//
//  Created by Eoin O'Connell on 19/02/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI

class AnnouncementExpandedView: CampaignView, UIScrollViewDelegate {
    var campaign: Campaign! {
        didSet{
            setupForCampaign()
        }
    }
    
    struct ConstraintChanges {
        
        private let topConstraint: (reg: CGFloat, compact: CGFloat) = (120, 10)
        private let bottomConstraint: (reg: CGFloat, compact: CGFloat) = (120, 10)
        
        var bottomConstant: CGFloat {
            if traitCollection.verticalSizeClass == .Compact {
                return bottomConstraint.compact
            }else{
                return bottomConstraint.reg
            }
        }
        
        var topConstant: CGFloat {
            if traitCollection.verticalSizeClass == .Compact {
                return topConstraint.compact
            }else{
                return topConstraint.reg
            }
        }
        
        var traitCollection: UITraitCollection
        init(traits: UITraitCollection) {
            self.traitCollection = traits
        }
        
    }
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var campaignCreatorImageView: UIImageView!
    @IBOutlet weak var campaignCreatorNameLabel: UILabel! {
        didSet{
            campaignCreatorNameLabel.text = ""
        }
    }
    @IBOutlet weak var campaignCreatorCompanyLabel: UILabel! {
        didSet {
            campaignCreatorCompanyLabel.text = ""
        }
    }
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var announcementTitleLabel: UILabel!
    @IBOutlet weak var announcementInfoTextView: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewContainer: UIView!
    
    let gradient = CAGradientLayer()
    
    @IBOutlet weak var ctaButton: UIButton! {
        didSet{
            ctaButton.layer.cornerRadius = 4
            ctaButton.clipsToBounds = true
            let background = DriftDataStore.sharedInstance.generateBackgroundColor()
            let foreground = DriftDataStore.sharedInstance.generateForegroundColor()
            ctaButton.backgroundColor = background
            ctaButton.setTitleColor(foreground, forState: .Normal)
        }
    }
    @IBOutlet weak var ctaHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    
    
    override func showOnWindow(window: UIWindow) {
        window.addSubview(self)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AnnouncementExpandedView.didRotate), name: UIApplicationDidChangeStatusBarOrientationNotification, object: nil)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        let leading = NSLayoutConstraint(item: self, attribute: .Leading, relatedBy: .Equal, toItem: window, attribute: .Leading, multiplier: 1.0, constant: 0)
        window.addConstraint(leading)
        let trailing = NSLayoutConstraint(item: self, attribute: .Trailing, relatedBy: .Equal, toItem: window, attribute: .Trailing, multiplier: 1.0, constant: 0)
        window.addConstraint(trailing)
        
        window.addConstraint(NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: window, attribute: .Bottom, multiplier: 1.0, constant: 0.0))
        
        window.addConstraint(NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: window, attribute: .Top, multiplier: 1.0, constant: 0))

        containerView.transform = CGAffineTransformMakeScale(0.00001, 0.00001)
        window.layoutIfNeeded()
        
        campaignCreatorNameLabel.textColor = ColorPalette.GrayColor
        campaignCreatorCompanyLabel.textColor = ColorPalette.GrayColor
        
        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 4
        
        campaignCreatorImageView.clipsToBounds = true
        campaignCreatorImageView.layer.cornerRadius = 3
        campaignCreatorImageView.contentMode = .ScaleAspectFill
        
        scrollView.delegate = self
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
        
        gradient.frame = CGRect(x: 0, y: 0, width: scrollViewContainer.frame.width, height: scrollViewContainer.frame.height)
        
        if scrollView.contentSize.height > scrollView.frame.size.height{
            gradient.colors = [
                UIColor.whiteColor().CGColor,
                UIColor.whiteColor().CGColor,
                UIColor.whiteColor().CGColor,
                UIColor.clearColor().CGColor
            ]
            scrollView.scrollEnabled = true
        }else{
            gradient.colors = [
                UIColor.whiteColor().CGColor,
                UIColor.whiteColor().CGColor,
                UIColor.whiteColor().CGColor,
                UIColor.whiteColor().CGColor
            ]
            scrollView.scrollEnabled = false
        }
        
        gradient.locations = [0, 0.2, 0.8, 1.0]
        scrollViewContainer.layer.mask = gradient
        
        closeButton.tintColor = ColorPalette.GrayColor
        
        
        window.setNeedsUpdateConstraints()
        UIView.animateWithDuration(0.4, delay: 0.5, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            window.layoutIfNeeded()
            self.containerView.transform = CGAffineTransformMakeScale(1, 1)
            self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        }, completion: nil)
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func didRotate(){
        let constants = ConstraintChanges(traits: traitCollection)
        containerTopConstraint.constant = constants.topConstant
        containerBottomConstraint.constant = constants.bottomConstant
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.gradient.frame = CGRect(x: 0, y: 0, width: self.scrollViewContainer.frame.width, height: self.scrollViewContainer.frame.height)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height{
            gradient.colors = [
                UIColor.clearColor().CGColor,
                UIColor.whiteColor().CGColor,
                UIColor.whiteColor().CGColor,
                UIColor.whiteColor().CGColor
            ]
        }else if scrollView.contentOffset.y > 0{
            gradient.colors = [
                UIColor.clearColor().CGColor,
                UIColor.whiteColor().CGColor,
                UIColor.whiteColor().CGColor,
                UIColor.clearColor().CGColor
            ]
        }else if scrollView.contentOffset.y <= 0{
            gradient.colors = [
                UIColor.whiteColor().CGColor,
                UIColor.whiteColor().CGColor,
                UIColor.whiteColor().CGColor,
                UIColor.clearColor().CGColor
            ]
        }
    }
    
    func setupForCampaign() {
        
        if let cta = campaign.announcementAttributes?.cta {
            if let copy = cta.copy {
                ctaButton.setTitle(copy, forState: .Normal)
            }else{
                ctaButton.setTitle("Find Out More", forState: .Normal)
            }
        }else{
            ctaButton.hidden = true
            ctaHeightConstraint.constant = 0
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
        }
        
        if let announcement = campaign.announcementAttributes {
            announcementTitleLabel.text = announcement.title ?? ""
            
            do {
                let htmlStringData = (campaign.bodyText ?? "").dataUsingEncoding(NSUTF8StringEncoding)!
                let options: [String: AnyObject] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                    NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
                ]
                let attributedHTMLString = try NSMutableAttributedString(data: htmlStringData, options: options, documentAttributes: nil)
                announcementInfoTextView.text = attributedHTMLString.string
            } catch {
                announcementInfoTextView.text = campaign.bodyText ?? ""
            }
            
            announcementInfoTextView.font = UIFont(name: "Avenir", size: 16)
            
        }
    
        if let organizerId = campaign.authorId {
            
            APIManager.getUser(organizerId, orgId: DriftDataStore.sharedInstance.embed!.orgId, authToken: DriftDataStore.sharedInstance.auth!.accessToken, completion: { (result) -> () in
                switch result {
                case .Success(let users):
                    if let avatar = users.first?.avatarURL {
                        self.campaignCreatorImageView.af_setImageWithURL(NSURL.init(string:avatar)!)
                    }
                    if let creatorName = users.first?.name {
                        self.campaignCreatorNameLabel.text = creatorName
                    }
                case .Failure(_):
                    ()
                }
            })
        }
    
        campaignCreatorCompanyLabel.text = DriftDataStore.sharedInstance.embed?.organizationName ?? ""
        layoutIfNeeded()
    }
    
    @IBAction func ctaButtonPressed(sender: AnyObject) {
        delegate?.campaignDidFinishWithResponse(self, campaign: campaign, response: .Announcement(.Clicked))
        
        if let cta = campaign?.announcementAttributes?.cta {
            
            switch cta.ctaType {
            case .Some(.ChatResponse):
                PresentationManager.sharedInstance.showNewConversationVC(campaign.authorId)
            case .Some(.LinkToURL):
                if let url = cta.urlLink {
                    presentURL(url)
                }
            default:
                LoggerManager.log("No CTA")
            }
            
        }else{
            //Read
            LoggerManager.log("No CTA")
        }
    }
    
    func presentURL(url: NSURL) {
        
        if #available(iOS 9.0, *) {
            if let topVC = TopController.viewController() where ["http", "https"].contains(url.scheme.lowercaseString) {
                let safari = SFSafariViewController(URL: url)
                topVC.presentViewController(safari, animated: true, completion: nil)
                return
            }
        }else{
            UIApplication.sharedApplication().openURL(url)
        }
    }

    
    @IBAction func pressedClose(sender: AnyObject) {
        delegate?.campaignDidFinishWithResponse(self, campaign: campaign, response: .Announcement(.Dismissed))
    }
    
    override func hideFromWindow() {
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.containerView.transform = CGAffineTransformMakeScale(0.0001, 0.0001)
            self.backgroundColor = UIColor.clearColor()
        }) { (success) -> Void in
            self.alpha = 0
            if success {
                self.removeFromSuperview()
            }
        }
    }
}
