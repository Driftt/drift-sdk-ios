//
//  ConversationImageTableViewCell.swift
//  Drift
//
//  Created by Brian McDonald on 01/08/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit

class ConversationImageTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var attachmentImageView: UIImageView!
    
    weak var delegate: AttachementSelectedDelegate?{
        didSet{
            let gestureRecognizer = UITapGestureRecognizer.init(target:self, action: #selector(ConversationImageTableViewCell.imagePressed))
            attachmentImageView.addGestureRecognizer(gestureRecognizer)
        }
    }
    var dateFormatter: DriftDateFormatter = DriftDateFormatter()
    var message: Message? {
        didSet{
            displayMessage()
        }
    }
    
    var attachment: Attachment? {
        didSet{
            displayAttachment()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func imagePressed(){
        if let attachment = attachment{
            delegate?.attachmentSelected(attachment, sender: self)
        }
    }
    
    func displayMessage(){
        if let authorId = message?.authorId{
            getUser(authorId)
        }
        avatarImageView.image = UIImage.init(named: "placeholderAvatar", inBundle: NSBundle.init(forClass: ConversationListTableViewCell.classForCoder()), compatibleWithTraitCollection: nil)
        messageTextView.text = ""
        messageTextView.textContainerInset = UIEdgeInsetsZero
        messageTextView.text = self.message!.body
        
        avatarImageView.layer.masksToBounds = true
        avatarImageView.contentMode = .ScaleAspectFill
        avatarImageView.layer.cornerRadius = 3
        
        attachmentImageView.layer.masksToBounds = true
        attachmentImageView.contentMode = .Center
        attachmentImageView.layer.cornerRadius = 3
        
        nameLabel.textColor = DriftDataStore.primaryFontColor
        
        timeLabel.textColor = DriftDataStore.secondaryFontColor
        timeLabel.text = self.dateFormatter.createdAtStringFromDate(self.message!.createdAt)
        do {
            let htmlStringData = (self.message!.body ?? "").dataUsingEncoding(NSUTF8StringEncoding)!
            let options: [String: AnyObject] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
            ]
            let attributedHTMLString = try NSMutableAttributedString(data: htmlStringData, options: options, documentAttributes: nil)
            self.messageTextView.text = attributedHTMLString.string
        } catch {
            self.messageTextView.text = ""
        }
    }
    
    func displayAttachment(){
        if let attachment = attachment{
            if let previewString = attachment.publicPreviewURL, imageURL = NSURL(string: previewString){
                attachmentImageView!.af_setImageWithURL(imageURL, placeholderImage: nil, filter: nil, progress: nil, progressQueue: dispatch_get_main_queue(), imageTransition: .CrossDissolve(0.5), runImageTransitionIfCached: true, completion: { (response) in
                    self.attachmentImageView.contentMode = .ScaleAspectFill
                })
            }
        }
    }
    
    func getUser(userId: Int){
        if let authorType = message!.authorType where authorType == .User{
            APIManager.getUser(message!.authorId, orgId: DriftDataStore.sharedInstance.embed!.orgId, authToken: DriftDataStore.sharedInstance.auth!.accessToken, completion: { (result) -> () in
                switch result {
                    
                case .Success(let users):
                    if let avatar = users.first?.avatarURL {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.avatarImageView.af_setImageWithURL(NSURL.init(string: avatar)!)
                        })
                    }
                    
                    if let creatorName =  users.first?.name {
                        self.nameLabel.text = creatorName
                    }
                case .Failure(let error):
                    LoggerManager.didRecieveError(error)
                }
            })
        }else{
            if let endUser = DriftDataStore.sharedInstance.auth?.enduser{
                if let avatar = endUser.avatarURL {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.avatarImageView.af_setImageWithURL(NSURL.init(string: avatar)!)
                    })
                }
                
                if let creatorName = endUser.name {
                    self.nameLabel.text = creatorName
                }
                
            }
        }
    }
    
}