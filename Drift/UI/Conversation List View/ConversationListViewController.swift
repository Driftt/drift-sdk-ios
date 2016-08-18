//
//  ConversationListViewController.swift
//  Drift
//
//  Created by Brian McDonald on 26/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit
import AlamofireImage

class ConversationListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingConversationsLabel: UILabel!
   
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateButton: UIButton!
    
    var conversations: [Conversation] = []
    var users: [CampaignOrganizer] = []
    var dateFormatter = DriftDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEmptyState()
        activityIndicator.startAnimating()
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        tableView.registerNib(UINib(nibName: "ConversationListTableViewCell", bundle:  NSBundle(forClass: ConversationListTableViewCell.classForCoder())), forCellReuseIdentifier: "ConversationListTableViewCell")
        InboxManager.sharedInstance.addConversationSubscription(ConversationSubscription(delegate: self))
        
        APIManager.getConversations(DriftDataStore.sharedInstance.auth!.enduser!.userId!, authToken: DriftDataStore.sharedInstance.auth!.accessToken) { (result) in
            self.activityIndicator.hidden = true
            self.loadingConversationsLabel.hidden = true
            self.activityIndicator.stopAnimating()
            switch result{
            case .Success(let conversations):
                self.conversations = conversations
                self.tableView.reloadData()
                if conversations.count == 0{
                    self.emptyStateView.hidden = false
                }
            case .Failure(let error):
                LoggerManager.log("Unable to get conversations for endUser:  \(DriftDataStore.sharedInstance.auth!.enduser!.userId!): \(error)")
            }
        }
    }
    
    
    convenience init() {
        self.init(nibName: "ConversationListViewController", bundle: NSBundle(forClass: ConversationListViewController.classForCoder()))
    }
    
    
    class func navigationController() -> UINavigationController {
        let vc = ConversationListViewController()
        let navVC = UINavigationController.init(rootViewController: vc)
        let leftButton = UIBarButtonItem(title: "Close", style: UIBarButtonItemStyle.Done, target: vc, action: #selector(ConversationListViewController.dismiss))
        let rightButton = UIBarButtonItem.init(image:  UIImage.init(named: "composeIcon", inBundle: NSBundle.init(forClass: ConversationListViewController.classForCoder()), compatibleWithTraitCollection: nil), style: UIBarButtonItemStyle.Plain, target: vc, action: #selector(ConversationListViewController.startNewConversation))
        navVC.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: DriftDataStore.sharedInstance.generateForegroundColor()]
        navVC.navigationBar.barTintColor = DriftDataStore.sharedInstance.generateBackgroundColor()
        navVC.navigationBar.tintColor = DriftDataStore.sharedInstance.generateForegroundColor()
        
        vc.navigationItem.leftBarButtonItem  = leftButton
        vc.navigationItem.rightBarButtonItem = rightButton
        vc.navigationItem.title = "Conversations"
        
        return navVC
    }
    
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func startNewConversation() {
        let conversationViewController = ConversationViewController(conversationType: ConversationViewController.ConversationType.CreateConversation(authorId: DriftDataStore.sharedInstance.auth!.enduser!.userId!))
        self.navigationController?.showViewController(conversationViewController, sender: self)
    }
    
    
    func setupEmptyState() {
        emptyStateButton.clipsToBounds = true
        emptyStateButton.layer.cornerRadius = 3.0
        emptyStateButton.backgroundColor = DriftDataStore.sharedInstance.generateBackgroundColor()
        emptyStateButton.setTitleColor(DriftDataStore.sharedInstance.generateForegroundColor(), forState: .Normal)
    }
    
    
    @IBAction func emptyStateButtonPressed(sender: AnyObject) {
        startNewConversation()
    }
    
}

extension ConversationListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ConversationListTableViewCell") as! ConversationListTableViewCell
        let conversation = conversations[indexPath.row]
        
        if let assigneeId = conversation.assigneeId where assigneeId != 0{
            UserManager.sharedInstance.userMetaDataForUserId(assigneeId, completion: { (user) in
            
                if let user = user {
                    if let avatar = user.avatarURL {
                        cell.avatarImageView.af_setImageWithURL(NSURL.init(string:avatar)!)
                    }
                    if let creatorName = user.name {
                        cell.nameLabel.text = creatorName
                    }
                }
            })
            
        }else{
            cell.nameLabel.text = "You"
        }
        
        if let string = conversation.preview{
            cell.messageLabel.text = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }

        cell.updatedAtLabel.text = dateFormatter.updatedAtStringFromDate(conversation.updatedAt)
        return cell
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if conversations.count > 0 {
            self.emptyStateView.hidden = true
        }
        return conversations.count
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let conversation = conversations[indexPath.row]
        let conversationViewController = ConversationViewController.init(conversationType: .ContinueConversation(conversationId: conversation.id))
        self.navigationController?.showViewController(conversationViewController, sender: self)
    }
}

extension ConversationListViewController: ConversationDelegate{
    
    func conversationDidUpdate(conversation: Conversation) {
        if let index = conversations.indexOf(conversation) {
            conversations[index] = conversation
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
        }else {
            conversations.insert(conversation, atIndex: 0)
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
        }
    }
    
    
    func conversationsDidUpdate(conversations: [Conversation]) {
        for conversation in conversations{
            if let index = self.conversations.indexOf(conversation) {
                if conversation.updatedAt.timeIntervalSince1970 > (self.conversations[index].updatedAt.timeIntervalSince1970){
                    self.conversations[index] = conversation
                }
            }else {
                self.conversations.append(conversation)
            }
        }
        tableView.reloadData()
    }
}