//
//  ConversationListViewController.swift
//  Drift
//
//  Created by Brian McDonald on 26/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit
import AlamofireImage
import SVProgressHUD

class ConversationListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
   
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateButton: UIButton!
    
    var enrichedConversations: [EnrichedConversation] = []
    var users: [CampaignOrganizer] = []
    var dateFormatter = DriftDateFormatter()
    var refreshControl: UIRefreshControl!
    
    var endUserId: Int?
    
    class func navigationController(endUserId: Int? = nil) -> UINavigationController {
        let vc = ConversationListViewController()
        vc.endUserId = endUserId
        let navVC = UINavigationController(rootViewController: vc)
        let leftButton = UIBarButtonItem(image: UIImage(named: "closeIcon", in: Bundle(for: Drift.self), compatibleWith: nil), style: UIBarButtonItemStyle.plain, target:vc, action: #selector(ConversationListViewController.dismissVC))
        leftButton.tintColor = DriftDataStore.sharedInstance.generateForegroundColor()
        
        let rightButton = UIBarButtonItem(image:  UIImage(named: "newChatIcon", in: Bundle(for: Drift.self), compatibleWith: nil), style: UIBarButtonItemStyle.plain, target: vc, action: #selector(ConversationListViewController.startNewConversation))
        rightButton.tintColor = DriftDataStore.sharedInstance.generateForegroundColor()
        
        navVC.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: DriftDataStore.sharedInstance.generateForegroundColor()]
        navVC.navigationBar.barTintColor = DriftDataStore.sharedInstance.generateBackgroundColor()
        navVC.navigationBar.tintColor = DriftDataStore.sharedInstance.generateForegroundColor()
        navVC.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: DriftDataStore.sharedInstance.generateForegroundColor(), NSFontAttributeName: UIFont(name: "AvenirNext-Medium", size: 16)!]
        
        vc.navigationItem.leftBarButtonItem  = leftButton
        vc.navigationItem.rightBarButtonItem = rightButton
        
        return navVC
    }
    
    convenience init() {
        self.init(nibName: "ConversationListViewController", bundle: Bundle(for: ConversationListViewController.classForCoder()))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let unableToAuthAlert = UIAlertController(title: "Unable to connect to chat", message: "Please try again later", preferredStyle: .alert)
        unableToAuthAlert.addAction(UIAlertAction.init(title: "OK", style: UIAlertActionStyle.cancel, handler: { (action) in
            self.dismissVC()
        }))

        if endUserId == nil, let embedId = DriftDataStore.sharedInstance.embed?.embedId, let userEmail = DriftDataStore.sharedInstance.userEmail, let userId = DriftDataStore.sharedInstance.userId {
            DriftManager.retrieveDataFromEmbeds(embedId, completion: { (success) in
                DriftManager.registerUser(userId, email: userEmail, attrs: nil, completion: { (endUserId) in
                    if let endUserId = endUserId {
                        self.endUserId = endUserId
                        self.getConversations()
                        return
                    }
                })
            })
            present(unableToAuthAlert, animated: true)
        }
        
        
        setupEmptyState()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 90
        tableView.separatorColor = UIColor(white: 0, alpha: 0.05)
        tableView.separatorInset = .zero
        tableView.register(UINib(nibName: "ConversationListTableViewCell", bundle:  Bundle(for: ConversationListTableViewCell.classForCoder())), forCellReuseIdentifier: "ConversationListTableViewCell")
        
        let tvc = UITableViewController()
        tvc.tableView = tableView
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(ConversationListViewController.getConversations), for: .valueChanged)
        tvc.refreshControl = refreshControl
        
        //Ensure that the back button title is not being shown
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        navigationItem.title = "Conversations"
        
        NotificationCenter.default.addObserver(self, selector: #selector(getConversations), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if enrichedConversations.count == 0{
            SVProgressHUD.show()
        }
        getConversations()
    }
    
    func dismissVC() {
        SVProgressHUD.dismiss()
        dismiss(animated: true, completion: nil)
    }
    
    func getConversations() {
        if let endUserId = endUserId{
            DriftAPIManager.getEnrichedConversations(endUserId) { (result) in
                self.refreshControl.endRefreshing()
                SVProgressHUD.dismiss()
                switch result{
                case .success(let enrichedConversations):
                    self.enrichedConversations = enrichedConversations
                    self.tableView.reloadData()
                    if self.enrichedConversations.count == 0{
                        self.emptyStateView.isHidden = false
                    }
                case .failure(let error):
                    SVProgressHUD.dismiss()
                    LoggerManager.log("Unable to get conversations for endUser:  \(self.endUserId): \(error)")
                }
                
            }

        }
    }
    
    func startNewConversation() {
        let conversationViewController = ConversationViewController(conversationType: ConversationViewController.ConversationType.createConversation(authorId: endUserId))
        navigationController?.show(conversationViewController, sender: self)
    }
    
    func setupEmptyState() {
        emptyStateButton.clipsToBounds = true
        emptyStateButton.layer.cornerRadius = 3.0
        emptyStateButton.backgroundColor = DriftDataStore.sharedInstance.generateBackgroundColor()
        emptyStateButton.setTitleColor(DriftDataStore.sharedInstance.generateForegroundColor(), for: UIControlState())
    }
    
    @IBAction func emptyStateButtonPressed(_ sender: AnyObject) {
        startNewConversation()
    }
    
}

extension ConversationListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationListTableViewCell") as! ConversationListTableViewCell
        cell.avatarImageView.image = UIImage(named: "placeholderAvatar", in: Bundle(for: Drift.self), compatibleWith: nil)
        let enrichedConversation = enrichedConversations[(indexPath as NSIndexPath).row]
        if let conversation = enrichedConversation.conversation {
            if enrichedConversation.unreadMessages > 0 {
                cell.unreadCountLabel.isHidden = false
                cell.unreadCountLabel.text = " \(enrichedConversation.unreadMessages) "
            }else{
                cell.unreadCountLabel.isHidden = true
            }
            
            if let assigneeId = conversation.assigneeId , assigneeId != 0{

                UserManager.sharedInstance.userMetaDataForUserId(assigneeId, completion: { (user) in

                    if let user = user {
                        if let avatar = user.avatarURL {
                            cell.avatarImageView.af_setImage(withURL: URL(string:avatar)!)
                        }
                        if let creatorName = user.name {
                            cell.nameLabel.text = creatorName
                        }
                    }
                })
                
            }else if let authorId = enrichedConversation.lastMessage?.authorId , authorId != 0{
                if authorId == endUserId {
                    
                    cell.nameLabel.text = "You"
                    if let endUser = DriftDataStore.sharedInstance.auth?.enduser {
                        if let avatar = endUser.avatarURL {
                            cell.avatarImageView.af_setImage(withURL: URL(string: avatar)!)
                        }
                    }
                }else{
                    UserManager.sharedInstance.userMetaDataForUserId(authorId, completion: { (user) in
                        
                        if let user = user {
                            if let avatar = user.avatarURL {
                                cell.avatarImageView.af_setImage(withURL: URL(string:avatar)!)
                            }
                            if let creatorName = user.name {
                                cell.nameLabel.text = creatorName
                            }
                        }
                    })
                }
            }
            
            if let preview = conversation.preview, preview != ""{
                cell.messageLabel.text = preview.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }else{
                cell.messageLabel.text = "📎 [Attachment]"
            }
            
            cell.updatedAtLabel.text = dateFormatter.updatedAtStringFromDate(conversation.updatedAt)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if enrichedConversations.count > 0 {
            self.emptyStateView.isHidden = true
        }
        return enrichedConversations.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let enrichedConversation = enrichedConversations[(indexPath as NSIndexPath).row]
        let conversationViewController = ConversationViewController(conversationType: .continueConversation(conversationId: enrichedConversation.conversation.id))
        navigationController?.show(conversationViewController, sender: self)
    }
    
}
