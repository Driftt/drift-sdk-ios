//
//  ObjectValidator.swift
//  Drift
//
//  Created by Brian McDonald on 25/07/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import UIKit
import ObjectMapper

private var failures = 0

extension Map{

    public func validNotEmpty<T>() -> T {
        if let value: T = value() {
            if value as? String == ""{
                failures += 1
                return dummyObject()
            }
            return value
        }else {
            // Collects failed count
            failures += 1
            return dummyObject()
        }
    }
    
    private func dummyObject<T>() -> T{
        let pointer = UnsafeMutablePointer<T>.alloc(0)
        pointer.dealloc(0)
        return pointer.memory
    }
    
    public var isValidNotEmpty: Bool{
        return failures == 0
    }
}
