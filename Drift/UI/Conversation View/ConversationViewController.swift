//
//  ConversationViewController.swift
//  Drift
//
//  Created by Brian McDonald on 28/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit
import SlackTextViewController
import QuickLook
import LayerKit
import ObjectMapper

class DriftPreviewItem: NSObject, QLPreviewItem{
    var previewItemURL: NSURL
    var previewItemTitle: String?
    
    init(url: NSURL, title: String){
        self.previewItemURL = url
        self.previewItemTitle = title
    }
}

public protocol AttachementSelectedDelegate: class{
    func attachmentSelected(attachment: Attachment, sender: AnyObject)
}

class ConversationViewController: SLKTextViewController {
    
    enum ConversationType {
        case CreateConversation(authorId: Int?)
        case ContinueConversation(conversationId: Int)
    }
    
    let emptyState = ConversationEmptyStateView.fromNib() as! ConversationEmptyStateView
    var sections: [[Message]] = []
    var previewItem: DriftPreviewItem?
    var dateFormatter: DriftDateFormatter = DriftDateFormatter()
    
    var conversationType: ConversationType! {
        didSet{
            if case ConversationType.ContinueConversation(let conversationId) = conversationType!{
                self.conversationId = conversationId
                InboxManager.sharedInstance.addMessageSubscription(MessageSubscription(delegate: self, conversationId: conversationId))
            }
        }
    }

    var conversationId: Int?{
        didSet{
            self.leftButton.enabled = true
            self.leftButton.tintColor = DriftDataStore.sharedInstance.generateBackgroundColor()
            self.leftButton.setImage(UIImage.init(named: "plus-circle", inBundle: NSBundle(forClass: Drift.self), compatibleWithTraitCollection: nil), forState: .Normal)
        }
    }
    
    func setConversationType(conversationType: ConversationType){
        self.conversationType = conversationType
    }
    
    convenience init(conversationType: ConversationType) {
        self.init(nibName: "ConversationViewController", bundle: NSBundle(forClass: ConversationViewController.classForCoder()))
        setConversationType(conversationType)
    }
    
    
    class func navigationController(conversationType: ConversationType) -> UINavigationController {
        let vc = ConversationViewController.init(conversationType: conversationType)
        let navVC = UINavigationController.init(rootViewController: vc)
        let leftButton = UIBarButtonItem(title: "Close", style: UIBarButtonItemStyle.Done, target: vc, action: #selector(ConversationViewController.dismiss))
        vc.navigationItem.leftBarButtonItem  = leftButton

        return navVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSlackTextView()
        
        tableView?.rowHeight = UITableViewAutomaticDimension
        tableView?.estimatedRowHeight = 65
        tableView?.registerNib(UINib.init(nibName: "ConversationMessageTableViewCell", bundle: NSBundle(forClass: ConversationMessageTableViewCell.classForCoder())), forCellReuseIdentifier: "ConversationMessageTableViewCell")
        tableView?.registerNib(UINib.init(nibName: "ConversationImageTableViewCell", bundle: NSBundle(forClass: ConversationImageTableViewCell.classForCoder())), forCellReuseIdentifier: "ConversationImageTableViewCell")
        tableView?.registerNib(UINib.init(nibName: "ConversationAttachmentsTableViewCell", bundle: NSBundle(forClass: ConversationAttachmentsTableViewCell.classForCoder())), forCellReuseIdentifier: "ConversationAttachmentsTableViewCell")
        
        if let navVC = navigationController {
            navVC.navigationBar.barTintColor = DriftDataStore.sharedInstance.generateBackgroundColor()
            navVC.navigationBar.tintColor = DriftDataStore.sharedInstance.generateForegroundColor()
            navVC.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: DriftDataStore.sharedInstance.generateForegroundColor()]
            navigationItem.title = "Conversation"
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.didOpen), name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        didOpen()
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func didOpen() {
        switch conversationType! {
        case .ContinueConversation(let conversationId):
            self.conversationId = conversationId
            getMessages(conversationId)
        case .CreateConversation(_):
            if let organizationName = DriftDataStore.sharedInstance.embed?.organizationName {
                emptyState.organizationLabel.text = organizationName
            }
        
            emptyState.messageLabel.backgroundColor = DriftDataStore.sharedInstance.generateBackgroundColor()
            emptyState.messageLabel.textColor = DriftDataStore.sharedInstance.generateForegroundColor()

            if let welcomeMessage = DriftDataStore.sharedInstance.embed?.welcomeMessage {
                emptyState.messageLabel.text = welcomeMessage
            }
            
            emptyState.center.x = view.center.x
            emptyState.center.y = view.center.y - UIScreen.mainScreen().bounds.height/4
            view.addSubview(emptyState)
        }
    }
    
    
    func setupSlackTextView() {
        leftButton.tintColor = UIColor.lightGrayColor()
        leftButton.enabled = false
        leftButton.setImage(UIImage.init(named: "plus-circle", inBundle: NSBundle(forClass: Drift.self), compatibleWithTraitCollection: nil), forState: .Normal)
        inverted = true
        shouldScrollToBottomAfterKeyboardShows = false
        bounces = true
        tableView?.separatorStyle = .None
        textView.placeholder = "Message"
    }
    
    
    override class func tableViewStyleForCoder(decoder: NSCoder) -> UITableViewStyle {
        return .Plain
    }
    
    
    func dismiss() {
        resignFirstResponder()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    override func didPressLeftButton(sender: AnyObject?) {

        let uploadController = UIAlertController.init(title: nil, message: nil, preferredStyle: .ActionSheet)
       
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            uploadController.modalPresentationStyle = .Popover
            let popover = uploadController.popoverPresentationController
            popover?.sourceView = self.leftButton
            popover?.sourceRect = self.leftButton.bounds
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        uploadController.addAction(UIAlertAction(title: "Take a Photo", style: .Default, handler: { (UIAlertAction) in
            imagePicker.sourceType = .Camera
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }))
        
        uploadController.addAction(UIAlertAction(title: "Choose From Library", style: .Default, handler: { (UIAlertAction) in
            imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }))

        uploadController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(uploadController, animated: true, completion: nil)
    }
    
    override func didPressRightButton(sender: AnyObject?) {
        let message = Message()
        message.body = textView.text
        message.authorId = Int(DriftDataStore.sharedInstance.auth!.enduser!.externalId!)
        self.textView.text = ""
        postMessage(message)
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let message = sections[indexPath.section][indexPath.row]
        
        var cell: UITableViewCell

        switch message.attachments.count{
        case 0:
            cell = tableView.dequeueReusableCellWithIdentifier("ConversationMessageTableViewCell", forIndexPath: indexPath) as! ConversationMessageTableViewCell
            if let cell = cell as? ConversationMessageTableViewCell{
                cell.message = message
            }
            
        case 1:
            cell = tableView.dequeueReusableCellWithIdentifier("ConversationImageTableViewCell", forIndexPath: indexPath) as! ConversationImageTableViewCell
            APIManager.getAttachmentsMetaData([message.attachments.first!], authToken: (DriftDataStore.sharedInstance.auth?.accessToken)!, completion: { (result) in
                switch result{
                case .Success(let attachments):
                    let fileName: NSString = attachments.first!.fileName
                    let fileExtension = fileName.pathExtension
                    if fileExtension == "jpg" || fileExtension == "png" || fileExtension == "gif"{
                        if let cell = cell as? ConversationImageTableViewCell{
                            cell.delegate = self
                            cell.message = message
                            cell.attachment = attachments.first
                        }
                    }else{
                        cell = tableView.dequeueReusableCellWithIdentifier("ConversationAttachmentsTableViewCell", forIndexPath: indexPath) as! ConversationAttachmentsTableViewCell
                        if let cell = cell as? ConversationAttachmentsTableViewCell{
                            cell.delegate = self
                            cell.message = message
                        }
                    }
                    
                case .Failure:
                    LoggerManager.log("Failed to get attachment metadata for id: \(message.attachments.first)")
                }
            })
            
        default:
            cell = tableView.dequeueReusableCellWithIdentifier("ConversationAttachmentsTableViewCell", forIndexPath: indexPath) as! ConversationAttachmentsTableViewCell
            if let cell = cell as? ConversationAttachmentsTableViewCell{
                cell.delegate = self
                cell.message = message
            }
        }
        
        cell.transform = tableView.transform
        return cell
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sections[section].count > 0{
            emptyState.hidden = true
        }
        return sections[section].count
    }

    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView: MessageTableHeaderView =  MessageTableHeaderView.fromNib("MessageTableHeaderView") as! MessageTableHeaderView
        
        //This handles the fact we need to have a header on the last (top when inverted) section.
        if section == 0{
            return nil
        }else if sections[section-1].count == 0 {
            headerView.headerLabel.text = "Today"
        }else {
            let message = sections[section-1][0]
            headerView.headerLabel.text = dateFormatter.headerStringFromDate(message.createdAt)
        }
        
        headerView.transform = tableView.transform
        return headerView
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
            return 0
        }else{
            return 42
        }
    }
    
    func addMessageToConversation(message: Message){
        if sections.count > 0 && NSCalendar.currentCalendar().component(.Day, fromDate: (sections[0].first?.createdAt)!) ==  NSCalendar.currentCalendar().component(.Day, fromDate: NSDate()){
            self.sections[0].insert(message, atIndex: 0)
            tableView!.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Bottom)
        }else{
            self.sections.insert([message], atIndex: 0)
            tableView?.insertSections(NSIndexSet.init(index: 0), withRowAnimation: .Bottom)
        }
    }
    
    
    func getSections(messages: [Message]) -> [[Message]]{
        let messagesReverse = messages.sort({ $0.createdAt.compare($1.createdAt) == .OrderedDescending})
        
        var sections: [[Message]] = []
        var section: [Message] = []
        
        for message in messagesReverse{
            if section.count == 0{
                section.append(message)
            }else{
                let anchorMessage = section[0]
                if  NSCalendar.currentCalendar().component(.Day, fromDate: message.createdAt) !=  NSCalendar.currentCalendar().component(.Day, fromDate: anchorMessage.createdAt) ||  NSCalendar.currentCalendar().component(.Month, fromDate: message.createdAt) !=  NSCalendar.currentCalendar().component(.Month, fromDate: anchorMessage.createdAt) ||  NSCalendar.currentCalendar().component(.Year, fromDate: message.createdAt) !=  NSCalendar.currentCalendar().component(.Year, fromDate: anchorMessage.createdAt){
                    sections.append(section)
                    section = []
                }
                section.append(message)
                
                if messages.count-1 == messagesReverse.indexOf(message){
                    sections.append(section)
                }
            }
        }
        
        if sections.count == 0 && section.count > 0{
            sections.append(section)
        }
        
        sections.append([])

        return sections
    }

    
    func getMessages(conversationId: Int){
        APIManager.getMessages(conversationId, authToken: DriftDataStore.sharedInstance.auth!.accessToken) { (result) in
            switch result{
            case .Success(let messages):
                let sorted = messages.sort({ $0.createdAt.compare($1.createdAt) == .OrderedAscending})
                    self.sections = self.getSections(sorted)
                    self.tableView?.reloadData()
            case .Failure:
                LoggerManager.log("Unable to get messages for conversationId: \(conversationId)")
            }
        }
    }
    
    
    func postMessage(messageRequest: Message){
        messageRequest.requestId = NSDate().timeIntervalSince1970
        addMessageToConversation(messageRequest)
        
        switch conversationType! {
        case .CreateConversation(let authodId):
            createConversationWithMessage(messageRequest, authorId: authodId)
        case .ContinueConversation(let conversationId):
            postMessageToConversation(conversationId, messageRequest: messageRequest)
        }
    }
    
    
    func postMessageToConversation(conversationId: Int, messageRequest: Message) {
        InboxManager.sharedInstance.postMessage(messageRequest, conversationId: conversationId) { (message, requestId) in
            if let index = self.sections[0].indexOf({ (message1) -> Bool in
                if message1.requestId == messageRequest.requestId{
                    return true
                }
                return false
            }){
                if let message = message{
                    message.sendStatus = .Sent
                    self.sections[0][index] = message
                    
                }else{
                    let message = Message()
                    message.authorId = DriftDataStore.sharedInstance.auth?.enduser?.userId
                    message.body = messageRequest.body
                    message.requestId = messageRequest.requestId
                    message.sendStatus = .Failed
                    self.sections[0][index] = message
                }
            }
        }
    }
    
    
    func createConversationWithMessage(messageRequest: Message, authorId: Int?) {
        InboxManager.sharedInstance.createConversation(messageRequest, authorId: authorId) { (message, requestId) in
            if let index = self.sections[0].indexOf({ (message1) -> Bool in
                if message1.requestId == messageRequest.requestId{
                    return true
                }
                return false
            }){
                if let message = message{
                    self.conversationType = ConversationType.ContinueConversation(conversationId: message.conversationId)
                    message.sendStatus = .Sent
                    self.sections[0][index] = message
                    self.conversationId = message.conversationId
                }else{
                    let message = Message()
                    message.authorId = DriftDataStore.sharedInstance.auth?.enduser?.userId
                    message.body = messageRequest.body
                    message.requestId = messageRequest.requestId
                    message.sendStatus = .Failed
                    self.sections[0][index] = message
                }
                
                self.tableView!.reloadRowsAtIndexPaths([NSIndexPath(forRow:0, inSection: 0)], withRowAnimation: .None)
                self.tableView?.scrollToRowAtIndexPath(NSIndexPath(forRow:0, inSection: 0), atScrollPosition: .Bottom, animated: true)
            }
        }
    }
}

extension ConversationViewController: MessageDelegate {
    
    func messagesDidUpdate(messages: [Message]) {
        let sorted = messages.sort({ $0.createdAt.compare($1.createdAt) == .OrderedAscending})
        self.sections = self.getSections(sorted)
        self.tableView?.reloadData()
    }
    
    
    func newMessage(message: Message) {
        if let uuid = message.uuid{
            CampaignsManager.markConversationAsRead(uuid)
        }
        if message.authorId != DriftDataStore.sharedInstance.auth?.enduser?.userId{
            if let index = checkSectionsForMessages(message){
                    sections[index.section][index.row] = message
                    tableView!.reloadRowsAtIndexPaths([index], withRowAnimation: .Bottom)
            }else{
                if NSCalendar.currentCalendar().component(.Day, fromDate: (sections[0].first?.createdAt)!) ==  NSCalendar.currentCalendar().component(.Day, fromDate: NSDate()){
                    self.sections[0].insert(message, atIndex: 0)
                    tableView!.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Bottom)
                }else{
                    self.sections.insert([message], atIndex: 0)
                    tableView?.insertSections(NSIndexSet.init(index: 0), withRowAnimation: .Bottom)
                }
            }
        }
    }
    
    
    func checkSectionsForMessages(message: Message) -> NSIndexPath? {
        if let section = sections.indexOf({ $0.contains(message) }) {
            if let row = sections[section].indexOf(message) {
                return NSIndexPath(forRow: row, inSection: section)
            }
        }
        return nil
    }
    
}

extension ConversationViewController: AttachementSelectedDelegate {
    
    func attachmentSelected(attachment: Attachment, sender: AnyObject) {
        APIManager.downloadAttachmentFile(attachment, authToken: (DriftDataStore.sharedInstance.auth?.accessToken)!) { (result) in
            switch result{
            case .Success(let tempFileURL):

                if sender.classForCoder == ConversationImageTableViewCell.classForCoder(){
                    self.previewItem = DriftPreviewItem(url: tempFileURL, title: attachment.fileName)
                    let qlController = QLPreviewController()
                    qlController.dataSource = self
                    self.presentViewController(qlController, animated: true, completion: nil)
                }else{
                    let interactionController = UIDocumentInteractionController()
                    interactionController.URL = tempFileURL
                    interactionController.name = attachment.fileName
                    interactionController.presentOptionsMenuFromRect(CGRectZero, inView: self.view, animated: true)
                }
            case .Failure:
                let alert = UIAlertController.init(title: "Unable to preview file", message: "This file cannot be previewed", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                LoggerManager.log("Unable to preview file with mimeType: \(attachment.mimeType)")
            }
        }
    }
}

extension ConversationViewController: QLPreviewControllerDataSource {
    
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
        if let previewItem = previewItem{
            return previewItem
        }
        return NSURL()
    }
}

extension ConversationViewController: UIDocumentInteractionControllerDelegate{
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerViewForPreview(controller: UIDocumentInteractionController) -> UIView? {
        return self.view
    }
    
    func documentInteractionControllerRectForPreview(controller: UIDocumentInteractionController) -> CGRect {
        return self.view.frame
    }
}


extension ConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        if let imageRep = UIImageJPEGRepresentation(image, 0.2){
            let newAttachment = Attachment()
            newAttachment.data = imageRep
            newAttachment.conversationId = conversationId!
            newAttachment.mimeType = "image/jpeg"
            newAttachment.fileName = "image.jpg"
            
            APIManager.postAttachment(newAttachment,authToken: DriftDataStore.sharedInstance.auth!.accessToken) { (result) in
                switch result{
                case .Success(let attachment):
                    let messageRequest = Message()
                    messageRequest.attachments.append(attachment.id)
                    self.postMessage(messageRequest)
                case .Failure:
                    let alert = UIAlertController.init(title: "Unable to upload file", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction.init(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    LoggerManager.log("Unable to upload file with mimeType: \(newAttachment.mimeType)")

                }
            }
        }
    }
    
}