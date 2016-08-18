//
//  APITests.swift
//  Drift
//
//  Created by Eoin O'Connell on 04/03/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import XCTest
import ObjectMapper
@testable import Drift


class APITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Drift.logout()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAuth() {
        
        let expectation = expectationWithDescription("API Will call Auth")
        
        let embed = Mapper<Embed>().map(JSONStore.convertStringToDictionary(JSONStore.embedJSONCorrect)!)

        XCTAssertNotNil(embed)
        DriftDataStore.sharedInstance.setEmbed(embed!)
        
        DriftManager.getAuth("eoin@8bytes.ie", userId: "7") { (success) -> () in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { (_) -> Void in
            XCTAssertNotNil(DriftDataStore.sharedInstance.auth)
        }
    }
    
    
    func testEmbed(){
        
        let expectation = expectationWithDescription("API Will call Embed")

        DriftManager.getEmbedData("u4r5t7h6w6h5-dev") { (success) -> () in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { (_) -> Void in
            XCTAssertNotNil(DriftDataStore.sharedInstance.embed)
        }
        
    }
    
}
