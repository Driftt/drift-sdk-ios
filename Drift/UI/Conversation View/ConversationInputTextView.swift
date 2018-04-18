//
//  ConversationInputTextView.swift
//  Drift-SDK
//
//  Created by Eoin O'Connell on 29/01/2018.
//  Copyright © 2018 Drift. All rights reserved.
//

import UIKit

class ConversationInputTextView: UITextView {

    // MARK: - Properties
    
    open override var text: String! {
        didSet {
            placeholderLabel.isHidden = !text.isEmpty
        }
    }
    
    open override var attributedText: NSAttributedString! {
        didSet {
            placeholderLabel.isHidden = !text.isEmpty
        }
    }
    
    /// A UILabel that holds the InputTextView's placeholder text
    open let placeholderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = ColorPalette.navyDark
        label.text = "Type your message..."
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// The placeholder text that appears when there is no text. The default value is "New Message"
    open var placeholder: String? = "Type your message..." {
        didSet {
            placeholderLabel.text = placeholder
        }
    }
    

    
    /// The font of the InputTextView. When set the placeholderLabel's font is also updated
    open override var font: UIFont! {
        didSet {
            placeholderLabel.font = font
        }
    }
    
    /// The textAlignment of the InputTextView. When set the placeholderLabel's textAlignment is also updated
    open override var textAlignment: NSTextAlignment {
        didSet {
            placeholderLabel.textAlignment = textAlignment
        }
    }
    
    open override var scrollIndicatorInsets: UIEdgeInsets {
        didSet {
            // When .zero a rendering issue can occur
            if scrollIndicatorInsets == .zero {
                scrollIndicatorInsets = UIEdgeInsets(top: .leastNonzeroMagnitude,
                                                     left: .leastNonzeroMagnitude,
                                                     bottom: .leastNonzeroMagnitude,
                                                     right: .leastNonzeroMagnitude)
            }
        }
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    /// Sets up the default properties
     func setup() {
        
        font = UIFont.preferredFont(forTextStyle: .body)
        textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 60)
        scrollIndicatorInsets = UIEdgeInsets(top: .leastNonzeroMagnitude,
                                             left: .leastNonzeroMagnitude,
                                             bottom: .leastNonzeroMagnitude,
                                             right: .leastNonzeroMagnitude)
        isScrollEnabled = false
        allowsEditingTextAttributes = false
        setupPlaceholderLabel()
        
    }
    
    /// Adds the placeholderLabel to the view and sets up its initial constraints
    private func setupPlaceholderLabel() {
        
        addSubview(placeholderLabel)
        
        let centreY = placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        let centreX = placeholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        
        centreY.priority = .defaultLow
        centreX.priority = .defaultLow
        
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: textContainerInset.top),
            placeholderLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: textContainerInset.bottom),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: textContainerInset.left + textContainer.lineFragmentPadding),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -textContainerInset.right),
            centreX,
            centreY
        ])
    }
}

