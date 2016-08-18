//
//  ConversationAttachmentsTableViewCell.swift
//  Drift
//
//  Created by Brian McDonald on 01/08/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit

class ConversationAttachmentsTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var attachmentsCollectionView: UICollectionView!
    
    var dateFormatter: DriftDateFormatter = DriftDateFormatter()
    var attachments: [Attachment] = []
    var message: Message? {
        didSet{
            displayMessage()
            getAttachmentsMetaData()
        }
    }
    weak var delegate: AttachementSelectedDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
        attachmentsCollectionView.registerNib(UINib.init(nibName: "AttachmentCollectionViewCell", bundle: NSBundle(forClass: AttachmentCollectionViewCell.classForCoder())), forCellWithReuseIdentifier: "AttachmentCollectionViewCell")
        attachmentsCollectionView.dataSource = self
        attachmentsCollectionView.delegate = self
        attachmentsCollectionView.backgroundColor = UIColor.whiteColor()
    }
    
    
    func displayMessage() {
        if let authorId = message?.authorId{
            getUser(authorId)
        }
        avatarImageView.image = UIImage.init(named: "placeholderAvatar", inBundle: NSBundle.init(forClass: ConversationListTableViewCell.classForCoder()), compatibleWithTraitCollection: nil)
        avatarImageView.layer.masksToBounds = true
        avatarImageView.contentMode = .ScaleAspectFill
        avatarImageView.layer.cornerRadius = 3
        
        messageTextView.text = ""
        messageTextView.textContainerInset = UIEdgeInsetsZero
        messageTextView.text = self.message!.body
        
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
    
    
    func getUser(userId: Int){
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
    
    
    func getAttachmentsMetaData() {
        if let message = message{
            APIManager.getAttachmentsMetaData(message.attachments, authToken: (DriftDataStore.sharedInstance.auth?.accessToken)!, completion: { (result) in
                switch result{
                    
                case .Success(let attachments):
                    self.attachments = attachments
                    self.attachmentsCollectionView.reloadData()
                    
                case .Failure(let error):
                    LoggerManager.log("Unable to get attachments: \(error)")
                }
            })
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? AttachmentCollectionViewCell {
            let attachment = self.attachments[indexPath.row]
            let fileName: NSString = attachment.fileName
            let fileExtension = fileName.pathExtension
            cell.fileNameLabel.text = "\(fileName)"
            cell.fileExtensionLabel.text = "\(fileExtension.uppercaseString)"
            
            let formatter = NSByteCountFormatter()
            formatter.stringFromByteCount(Int64(attachment.size))
            formatter.allowsNonnumericFormatting = false
            cell.sizeLabel.text = formatter.stringFromByteCount(Int64(attachment.size))
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AttachmentCollectionViewCell", forIndexPath: indexPath) as! AttachmentCollectionViewCell
        cell.layer.cornerRadius = 3.0
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if delegate != nil{
            delegate?.attachmentSelected(attachments[indexPath.row], sender: self)
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(200, 55)
    }
    

}
