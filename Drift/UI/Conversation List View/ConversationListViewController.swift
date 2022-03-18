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
   
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            if #available(iOS 13.0, *) {
                activityIndicator.style = .large
            } else {
                activityIndicator.style = .gray
            }
            activityIndicator.hidesWhenStopped = true
        }
    }
    
    var enrichedConversations: [EnrichedConversation] = []
    var users: [User] = []
    var dateFormatter = DriftDateFormatter()
    var refreshControl: UIRefreshControl!
    
    var endUserId: Int64?
    
    class func navigationController(endUserId: Int64? = nil) -> UINavigationController {
        let vc = ConversationListViewController()
        vc.endUserId = endUserId
        let navVC = UINavigationController(rootViewController: vc)
        let leftButton = UIBarButtonItem(image: UIImage(named: "closeIcon", in: Bundle.drift_getResourcesBundle(), compatibleWith: nil), style: UIBarButtonItem.Style.plain, target:vc, action: #selector(ConversationListViewController.dismissVC))
        leftButton.tintColor = DriftDataStore.sharedInstance.generateForegroundColor()
        
        let rightButton = UIBarButtonItem(image:  UIImage(named: "newChatIcon", in: Bundle.drift_getResourcesBundle(), compatibleWith: nil), style: UIBarButtonItem.Style.plain, target: vc, action: #selector(ConversationListViewController.startNewConversation))
        rightButton.tintColor = DriftDataStore.sharedInstance.generateForegroundColor()
        
        navVC.modalPresentationStyle = .fullScreen
        navVC.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: DriftDataStore.sharedInstance.generateForegroundColor()]
        navVC.navigationBar.barTintColor = DriftDataStore.sharedInstance.generateBackgroundColor()
        navVC.navigationBar.tintColor = DriftDataStore.sharedInstance.generateForegroundColor()
        navVC.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: DriftDataStore.sharedInstance.generateForegroundColor(), NSAttributedString.Key.font: UIFont(name: "AvenirNext-Medium", size: 16)!]
        
        if #available(iOS 15.0, *) {
            
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.backgroundColor = DriftDataStore.sharedInstance.generateBackgroundColor()
            navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: DriftDataStore.sharedInstance.generateForegroundColor(), NSAttributedString.Key.font: UIFont(name: "AvenirNext-Medium", size: 16)!]
            navVC.navigationBar.standardAppearance = navigationBarAppearance
            navVC.navigationBar.compactAppearance = navigationBarAppearance
            navVC.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        }
        
        vc.navigationItem.leftBarButtonItem  = leftButton
        vc.navigationItem.rightBarButtonItem = rightButton
        
        return navVC
    }
    
    convenience init() {
        self.init(nibName: "ConversationListViewController", bundle: Bundle.drift_getResourcesBundle())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let unableToAuthAlert = UIAlertController(title: "Unable to connect to chat", message: "Please try again later", preferredStyle: .alert)
        unableToAuthAlert.addAction(UIAlertAction.init(title: "OK", style: UIAlertAction.Style.cancel, handler: { (action) in
            self.dismissVC()
        }))

        if endUserId == nil, let embedId = DriftDataStore.sharedInstance.embed?.embedId, let userEmail = DriftDataStore.sharedInstance.userEmail, let userId = DriftDataStore.sharedInstance.userId, let userJwt = DriftDataStore.sharedInstance.userJwt {
            DriftManager.retrieveDataFromEmbeds(embedId, completion: { (success) in
                DriftManager.registerUser(userId, email: userEmail, userJwt: userJwt, attrs: nil, completion: { (endUserId) in
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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90
        tableView.separatorColor = ColorPalette.dividerColor
        tableView.separatorInset = .zero
        tableView.register(UINib(nibName: "ConversationListTableViewCell", bundle:  Bundle.drift_getResourcesBundle()), forCellReuseIdentifier: "ConversationListTableViewCell")
        
        let tvc = UITableViewController()
        tvc.tableView = tableView
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(ConversationListViewController.getConversations), for: .valueChanged)
        tvc.refreshControl = refreshControl
        
        activityIndicator.color = DriftDataStore.sharedInstance.generateBackgroundColor()
        
        //Ensure that the back button title is not being shown
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        navigationItem.title = "Conversations"
        
        NotificationCenter.default.addObserver(self, selector: #selector(getConversations), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveNewMessage), name: .driftOnNewMessageReceived, object: nil)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if enrichedConversations.count == 0{
            activityIndicator.startAnimating()
            
        }
        getConversations()
    }
    
    @objc func dismissVC() {
        activityIndicator.stopAnimating()
        dismiss(animated: true, completion: nil)
    }
    
    @objc func getConversations() {
        if let endUserId = endUserId{
            DriftAPIManager.getEnrichedConversations(endUserId) { [weak self] (result) in
                self?.refreshControl.endRefreshing()
                self?.activityIndicator.stopAnimating()
                switch result{
                case .success(let enrichedConversationsResult):
                    
                    if DriftManager.sharedInstance.shouldShowAutomatedMessages {
                        //Show all conversations
                       self?.enrichedConversations = enrichedConversationsResult
                    } else {
                        //Filter out conversations we dont have a status for (Automated is BulkSent)
                        self?.enrichedConversations = enrichedConversationsResult.filter({ $0.conversation.status != nil })
                    }
                    self?.tableView.reloadData()
                    if self?.enrichedConversations.count == 0{
                        self?.emptyStateView.isHidden = false
                    }
                case .failure(let error):
                    LoggerManager.log("Unable to get conversations for endUser:  \(self?.endUserId ?? -1): \(error)")
                }
                
            }

        }
    }
    
    @objc func startNewConversation() {
        let conversationViewController = ConversationViewController(conversationType: ConversationViewController.ConversationType.createConversation)
        navigationController?.show(conversationViewController, sender: self)
    }
    
    @objc func didReceiveNewMessage(){
        getConversations()
    }
    
    func setupEmptyState() {
        emptyStateButton.clipsToBounds = true
        emptyStateButton.layer.cornerRadius = 3.0
        emptyStateButton.backgroundColor = DriftDataStore.sharedInstance.generateBackgroundColor()
        emptyStateButton.setTitleColor(DriftDataStore.sharedInstance.generateForegroundColor(), for: UIControl.State())
    }
    
    @IBAction func emptyStateButtonPressed(_ sender: AnyObject) {
        startNewConversation()
    }
    
}

extension ConversationListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationListTableViewCell") as! ConversationListTableViewCell

        let enrichedConversation = enrichedConversations[indexPath.row]
        let conversation = enrichedConversation.conversation
        
        if enrichedConversation.unreadMessages > 0 {
            cell.unreadCountLabel.isHidden = false
            cell.unreadCountLabel.text = " \(enrichedConversation.unreadMessages) "
        }else{
            cell.unreadCountLabel.isHidden = true
        }
        
        
        if let lastMessageAuthorId = enrichedConversation.lastAgentMessage?.authorId ?? enrichedConversation.lastMessage?.preMessages.first?.user?.userId {
            
            UserManager.sharedInstance.userMetaDataForUserId(lastMessageAuthorId, completion: { (user) in
                
                cell.avatarImageView.setupForUser(user: user)
                
                if let user = user {
                    if let creatorName = user.name {
                        cell.nameLabel.text = creatorName
                    }
                }
            })
            
        } else {
            cell.avatarImageView.imageView.image = UIImage(named: "placeholderAvatar", in: Bundle.drift_getResourcesBundle(), compatibleWith: nil)
            cell.nameLabel.text = "Unknown User"
        }
        
        if let preview = conversation.preview, preview != ""{
            cell.messageLabel.text = preview.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }else{
            cell.messageLabel.text = "📎 [Attachment]"
        }
        
        cell.updatedAtLabel.text = dateFormatter.updatedAtStringFromDate(conversation.updatedAt)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if enrichedConversations.count > 0 {
            self.emptyStateView.isHidden = true
        }
        return enrichedConversations.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let enrichedConversation = enrichedConversations[indexPath.row]
        let conversationViewController = ConversationViewController(conversationType: .continueConversation(conversationId: enrichedConversation.conversation.id))
        navigationController?.show(conversationViewController, sender: self)
    }
    
}
