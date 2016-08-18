//
//  ConversationMessageTableViewCell.swift
//  Drift
//
//  Created by Brian McDonald on 01/08/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit
import AlamofireImage

class ConversationMessageTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    
    var dateFormatter: DriftDateFormatter = DriftDateFormatter()
    var message: Message? {
        didSet{
            displayMessage()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
    
    func displayMessage() {

        avatarImageView.image = UIImage.init(named: "placeholderAvatar", inBundle: NSBundle.init(forClass: ConversationListTableViewCell.classForCoder()), compatibleWithTraitCollection: nil)
        avatarImageView.layer.cornerRadius = 3
        avatarImageView.layer.masksToBounds = true
        
        messageTextView.text = ""
        messageTextView.textContainerInset = UIEdgeInsetsZero
        messageTextView.text = self.message!.body
        
        if let authorId = message?.authorId{
            getUser(authorId)
        }
        
        nameLabel.textColor = DriftDataStore.primaryFontColor

        timeLabel.textColor = DriftDataStore.secondaryFontColor
        timeLabel.text = self.dateFormatter.createdAtStringFromDate(self.message!.createdAt)
        
        do {
            let htmlStringData = (self.message!.body ?? "").dataUsingEncoding(NSUTF8StringEncoding)!
            let options: [String: AnyObject] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding]
            let attributedHTMLString = try NSMutableAttributedString(data: htmlStringData, options: options, documentAttributes: nil)
            self.messageTextView.text = attributedHTMLString.string
        } catch {
            self.messageTextView.text = ""
        }
    }
    
    func getUser(userId: Int) {
        
        if let authorType = message?.authorType where authorType == .User {
            UserManager.sharedInstance.userMetaDataForUserId(userId, completion: { (user) in
                
                if let user = user {
                    if let avatar = user.avatarURL, url = NSURL(string: avatar) {
                        self.avatarImageView.af_setImageWithURL(url)
                    }
                    
                    if let creatorName =  user.name {
                        self.nameLabel.text = creatorName
                    }
                }
            })
            
        }else {
            if let endUser = DriftDataStore.sharedInstance.auth?.enduser {
                if let avatar = endUser.avatarURL {
                    self.avatarImageView.af_setImageWithURL(NSURL.init(string: avatar)!)
                }
                
                if let creatorName = endUser.name {
                    self.nameLabel.text = creatorName
                }
            }
        }
    }
    
}
