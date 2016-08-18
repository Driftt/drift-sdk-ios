//
//  TopController.swift
//  Drift
//
//  Created by Eoin O'Connell on 25/02/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit

class TopController {

    /**
     Itterated throught View controllers in UIWindow and finds the top view controller recursively if a UINavigation or UITabBarController is found.
     
     - returns: UIViewController being presented to the user or nil

     */
    class func viewController(startController: UIViewController? = nil) -> UIViewController?{
        
        var topController = startController ?? UIApplication.sharedApplication().keyWindow?.rootViewController
        
        if topController != nil {
            while topController!.presentedViewController != nil {
                topController = topController!.presentedViewController
            }
        }
        
        if let navController = topController as? UINavigationController, top = navController.topViewController {
            return viewController(top)
        }else if let tabController = topController as? UITabBarController, current = tabController.selectedViewController {
            return viewController(current)
        }else if let presented = topController as? UIAlertController {
            return presented.presentingViewController
        }
        
        return topController
    }
    
    /**
     Checked if the top view controller in in a tab bar controller
     
     - returns: Bool idicating if top view controller is in a UITabBarController
     */
    class func hasTabBar() -> Bool{
        
        if let controller = viewController(), _ = controller.tabBarController {
            return true
        }
        return false
    }
}
