//
//  modelTests.swift
//  Drift
//
//  Created by Eoin O'Connell on 24/02/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import XCTest
import ObjectMapper
@testable import Drift

class ModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAuth() {
        XCTAssertNotNil(Mapper<Auth>().map(JSONStore.convertStringToDictionary(JSONStore.correctAuthJSON)!), "Auth Did not Map For correct JSON")
        XCTAssertNil(Mapper<Auth>().map(JSONStore.convertStringToDictionary(JSONStore.incompleteAuthJSON)!), "Auth mapped incorrect JSON")
        XCTAssertNil(Mapper<Auth>().map(JSONStore.convertStringToDictionary(JSONStore.authJSONEmptyAccessToken)!), "Auth mapped incorrect JSON when access token is empty String")
        XCTAssertNotNil(Mapper<Auth>().map(JSONStore.convertStringToDictionary(JSONStore.authJSONNoUser)!), "Auth mapping failed when no user")
    }
    
    func testEmbed(){
        XCTAssertNotNil(Mapper<Embed>().map(JSONStore.convertStringToDictionary(JSONStore.embedJSONCorrect)!), "Embed Did not Map For correct JSON")
        XCTAssertNil(Mapper<Embed>().map(JSONStore.convertStringToDictionary(JSONStore.embedJSONNoOrgId)!), "Embed Mapped embed with no orgId")
        XCTAssertNil(Mapper<Embed>().map(JSONStore.convertStringToDictionary(JSONStore.embedJSONEmptyOrgId)!), "Embed Mapped embed with string org Id")
        XCTAssertNil(Mapper<Embed>().map(JSONStore.convertStringToDictionary(JSONStore.embedJSONNoLayerAppId)!), "Embed Mapped embed with no layer app id")
        XCTAssertNil(Mapper<Embed>().map(JSONStore.convertStringToDictionary(JSONStore.embedJSONEmptyLayerAppId)!), "Embed Mapped embed with empty string layer app Id")
    }
    
    func testCampaignOrganizer() {
        XCTAssertNotNil(Mapper<CampaignOrganizer>().mapArray(JSONStore.convertStringToDictionaryArray(JSONStore.campaignOrganiserJSONCorrect)!)!.first, "")
        XCTAssertNotNil(Mapper<CampaignOrganizer>().mapArray(JSONStore.convertStringToDictionaryArray(JSONStore.campaignOrganiserJSONEmptyURL)!)!.first, "")
    }
    
}
