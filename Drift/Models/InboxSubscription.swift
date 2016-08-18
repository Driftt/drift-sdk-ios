//
//  InboxSubscription.swift
//  Drift
//
//  Created by Brian McDonald on 25/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

public protocol InboxDelegate: class{
    func inboxesDidUpdate(inboxes: [Inbox])
    func didSelectInbox(inbox: Inbox)
}

public class InboxSubscription {
    
    public convenience init(delegate: InboxDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    weak var delegate: InboxDelegate?
}

