//
//  APIManager.swift
//  Driftt
//
//  Created by Eoin O'Connell on 22/01/2016.
//  Copyright © 2016 Drift. All rights reserved.
//

import Foundation
import ObjectMapper

class APIManager {
    
    private let session: NSURLSession
    
    private static var sharedInstance: APIManager = APIManager()
    
    private init(){
        session = NSURLSession.sharedSession()
    }
        

    class func getAuth(email: String, userId: String, redirectURL: String, orgId: Int, clientId: String, completion: (Result<Auth>) -> ()) {
        
        let params: [String : AnyObject] = [
            
            "email": email,
            "org_id": orgId,
            "user_id": userId,
            "grant_type": "sdk",
            "redirect_uri":redirectURL,
            "client_id": clientId
        ]
        
        makeRequest(Request(url: URLStore.tokenURL).setMethod(.POST).setData(.FORM(json: params))) { (result) in
            completion(mapResponse(result))
        }
    }
    
    
    
    class func getLayerAccessToken(nonce: String, userId: String, completion: (Result<String>) -> ()){
        
        makeRequest(Request(url: URLStore.layerTokenURL).setMethod(.POST).setData(.JSON(json: ["nonce": nonce, "userId": userId]))) { (result) in
            
            switch result {
            case .Success(let json):
                if let token = json["identityToken"] as? String {
                    completion(.Success(token))
                    return
                }
                fallthrough
            default:
                completion(.Failure(DriftError.APIFailure))
            }
        }
    }
    
    class func getEmbeds(embedId: String, refreshRate: Int?, completion: (Result<Embed>) -> ()){
        
        guard let url = URLStore.embedURL(embedId, refresh: refreshRate) else {
            LoggerManager.log("Failure in Embed URL creation")
            return
        }
        
        makeRequest(Request(url: url).setMethod(.GET)) { (result) -> () in
            let response: Result<Embed> = mapResponse(result)
            completion(response)
        }
    }
    
    
    class func getUser(userId: Int, orgId: Int, authToken:String, completion: (Result<[CampaignOrganizer]>) -> ()) {
        
        guard let url = URLStore.campaignUserURL(orgId, authToken: DriftDataStore.sharedInstance.auth!.accessToken) else {
            LoggerManager.log("Failure in Campaign Organizer URL creation")
            return
        }
        
        let params: [String: AnyObject] =
        [   "avatar_w": 102,
            "avatar_h": 102,
            "avatar_fit": "1",
            "access_token": authToken,
            "userId": userId
        ]
        
        makeRequest(Request(url: url).setMethod(.GET).setData(.URL(params: params))) { (result) -> () in
            completion(mapResponse(result))
        }
        
    }
    
    class func getEndUser(endUserId: Int, authToken:String, completion: (Result<User>) -> ()){
        
        guard let url = URLStore.usersURL(endUserId, authToken: authToken) else {
            LoggerManager.log("Failure in User URL creation")
            return
        }
        
        makeRequest(Request(url: url).setMethod(.GET)) { (result) in
            completion(mapResponse(result))
        }
    }
    
    class func postIdentify(orgId: Int, userId: String, email: String, attributes: [String: AnyObject]?, completion: (Result<User>) -> ()) {
        
        var params: [String: AnyObject] = [
            "orgId": orgId,
            "userId": userId,
            "attributes": ["email": email]
        ]
        
        if var attributes = attributes {
            attributes["email"] = email
            params["attributes"] = attributes
        }
        
        makeRequest(Request(url: URLStore.identifyURL).setMethod(.POST).setData(.JSON(json: params))) { (result) -> () in
            completion(mapResponse(result))
        }
    }
    
    
    class func recordAnnouncement(conversationId: Int, authToken: String, response: AnnouncementResponse) {
        
        
        guard let url = URLStore.messagesURL(conversationId, authToken: authToken) else {
            LoggerManager.log("Failed in Messages URL Creation")
            return
        }
        
        let json: [String: AnyObject] = [
            "type": "CONVERSATION_EVENT",
            "conversationEvent": ["type": response.rawValue]]
    
        let request = Request(url: url).setData(.JSON(json: json)).setMethod(.POST)
        
        makeRequest(request) { (result) -> () in
            
            switch result {
            case .Success(let json):
                LoggerManager.log("Record Annouincment Success: \(json)")
            case .Failure(let error):
                LoggerManager.log("Record Announcement Failure: \(error)")
            }
        }
    }
    
    
    class func recordNPS(conversationId: Int, authToken: String, response: NPSResponse){
        
        
        guard let url = URLStore.messagesURL(conversationId, authToken: authToken) else {
            LoggerManager.log("Failed in Messages URL Creation")
            return
        }
        
        
        var attributes: [String: AnyObject] = [:]
        
        
        switch response{
        case .Dismissed:
            attributes = ["dismissed":true]
        case .Numeric(let numeric):
            attributes = ["numericResponse":numeric]
        case .TextAndNumeric(let numeric, let text):
            attributes = ["numericResponse":numeric, "textResponse": text]
        }
        
        let json: [String: AnyObject] = [
            "type": "NPS_RESPONSE",
            "attributes": attributes
        ]
        
        let request = Request(url: url).setData(.JSON(json: json)).setMethod(.POST)
        
        makeRequest(request) { (result) -> () in
            
            switch result {
            case .Success(let json):
                LoggerManager.log("Record NPS Success: \(json)")
            case .Failure(let error):
                LoggerManager.log("Record NPS Failure: \(error)")
            }
        }
    }
    
    
    class func getConversations(endUserId: Int, authToken: String, completion: (result: Result<[Conversation]>) -> ()){
        
        
        guard let url = URLStore.conversationsURL(endUserId, authToken: authToken) else {
            LoggerManager.log("Failed in Conversations URL Creation")
            return
        }
        
        let request = Request(url: url).setMethod(.GET)
        
        makeRequest(request) { (result) -> () in
            
            switch result {
            case .Success:
                let conversations: Result<[Conversation]> = mapResponse(result)
                completion(result: conversations)
            case .Failure(let error):
                completion(result: .Failure(DriftError.APIFailure))
                LoggerManager.log("Unable to get conversations for user: \(error)")
            }
        }
    }
    
   
    class func getMessages(conversationId: Int, authToken: String, completion: (result: Result<[Message]>) -> ()){
        
        
        guard let url = URLStore.messagesURL(conversationId, authToken: authToken) else {
            LoggerManager.log("Failed in Messages URL Creation")
            return
        }
        
        let request = Request(url: url).setMethod(.GET)
        
        makeRequest(request) { (result) -> () in
            
            switch result {
            case .Success:
                let messages: Result<[Message]> = mapResponse(result)
                completion(result: messages)
            case .Failure(let error):
                completion(result: .Failure(DriftError.APIFailure))
                LoggerManager.log("Unable to get messages for conversation: \(error)")
            }
        }
    }
    
    
    class func postMessage(conversationId: Int, message: Message, authToken: String, completion: (result: Result<Message>) -> ()){
        
        
        guard let url = URLStore.messagesURL(conversationId, authToken: authToken) else {
            LoggerManager.log("Failed in Messages URL Creation")
            return
        }
        
        let json = message.toJSON()
        
        let request = Request(url: url).setData(.JSON(json: json)).setMethod(.POST)
        
        makeRequest(request) { (result) -> () in
            
            switch result {
            case .Success:
                let messages: Result<Message> = mapResponse(result)
                completion(result: messages)
            case .Failure(let error):
                completion(result: .Failure(DriftError.APIFailure))
                LoggerManager.log("Unable to get messages for conversation: \(error)")
            }
        }

    }
    
    class func createConversation(body: String, authorId:Int?, authToken: String, completion: (result: Result<Message>) -> ()){
        
        
        guard let url = URLStore.createConversationURL(authToken) else {
            LoggerManager.log("Failed in Create Conversation URL Creation")
            return
        }
        
        let json: [String : AnyObject] = ["body":body]
        
        let request = Request(url: url).setData(.JSON(json: json)).setMethod(.POST)
        
        makeRequest(request) { (result) -> () in
            
            switch result {
            case .Success:
                let messages: Result<Message> = mapResponse(result)
                completion(result: messages)
            case .Failure(let error):
                completion(result: .Failure(DriftError.APIFailure))
                LoggerManager.log("Unable to get messages for conversation: \(error)")
            }
        }
        
    }
    
    class func downloadAttachmentFile(attachment: Attachment, authToken: String, completion: (result: Result<NSURL>) -> ()){
        guard let url = URLStore.downloadAttachmentURL(attachment.id, authToken: authToken) else {
            LoggerManager.log("Failed in Download Attachment URL Creation")
            return
        }
        
        sharedInstance.session.dataTaskWithURL(url) { (data, response, error) in
            if let response = response as? NSHTTPURLResponse {
                LoggerManager.log("API Complete: \(response.statusCode) \(response.URL?.path ?? "")")
            }
            
            if let data = data{
                let fileURL = DriftManager.sharedInstance.directoryURL.URLByAppendingPathComponent(attachment.fileName)
                do {
                    try data.writeToURL(fileURL, options: .AtomicWrite)
                    completion(result: .Success(fileURL))
                } catch {
                    completion(result: .Failure(DriftError.DataCreationFailure))
                }
            }else{
                completion(result: .Failure(DriftError.APIFailure))
            }
        }.resume()
    }
    
    class func getAttachmentsMetaData(attachmentIds: [Int], authToken: String, completion: (result: Result<[Attachment]>) -> ()){
        
        guard let url = URLStore.getAttachmentsURL(attachmentIds, authToken: authToken) else {
            LoggerManager.log("Failed in Get Attachment Metadata URL Creation")
            return
        }
        
        let request = Request(url: url).setMethod(.GET)
        
        makeRequest(request) { (result) -> () in
            
            switch result {
            case .Success:
                let attachments: Result<[Attachment]> = mapResponse(result)
                completion(result: attachments)
            case .Failure(let error):
                completion(result: .Failure(DriftError.APIFailure))
                LoggerManager.log("Unable to get attachments metadata: \(error)")
            }
        }
    }
    
    class func postAttachment(attachment: Attachment, authToken: String, completion: (result: Result<Attachment>) ->()){

        let boundary = "Boundary-\(NSUUID().UUIDString)"
        let requestURL = URLStore.postAttachmentURL(authToken)
        
        let request = NSMutableURLRequest.init(URL: requestURL!)
        
        request.HTTPMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let multipartBody = NSMutableData()
        multipartBody.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        multipartBody.appendData("Content-Disposition: form-data; name=\"conversationId\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        multipartBody.appendData("\(attachment.conversationId)\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        
        multipartBody.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        multipartBody.appendData("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        multipartBody.appendData("Content-Type: \(attachment.mimeType)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        multipartBody.appendData(attachment.data)
        multipartBody.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        
        multipartBody.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        request.HTTPBody = multipartBody
        sharedInstance.session.dataTaskWithRequest(request) { (data, response, error) in
            if let response = response as? NSHTTPURLResponse {
                LoggerManager.log("API Complete: \(response.statusCode) \(response.URL?.path ?? "")")
            }
            
            let accepted = [200, 201]
            
            if let response = response as? NSHTTPURLResponse, data = data where accepted.contains(response.statusCode){
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    if let attachment: Attachment = Mapper<Attachment>().map(json){
                        dispatch_async(dispatch_get_main_queue(), { 
                            completion(result: .Success(attachment))
                        })
                        return
                    }
                } catch {
                    print(request.HTTPBody)
                    print(response.statusCode)
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(result: .Failure(DriftError.APIFailure))
                    })
                }
            }else if let error = error {
                dispatch_async(dispatch_get_main_queue(), {
                    completion(result: .Failure(error))
                })
            }else{
                dispatch_async(dispatch_get_main_queue(), {
                    completion(result: .Failure(DriftError.APIFailure))
                })
            }
            
        }.resume()
    }
    
    /**
     Responsible for calling a request and parsing its response
     
     - parameter request: The request object to make the call
     - parameter completion: Completion Block called with result Object - AnyObject or nil
    */
    private class func makeRequest(request: Request, completion: (Result<AnyObject>) -> ()) {
        
        sharedInstance.session.dataTaskWithRequest(request.getRequest()) { (data, response, error) -> Void in
            if let response = response as? NSHTTPURLResponse {
                LoggerManager.log("API Complete: \(response.statusCode) \(response.URL?.path ?? "")")
            }

            let accepted = [200, 201]
            
            if let response = response as? NSHTTPURLResponse, data = data where accepted.contains(response.statusCode){
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    dispatch_async(dispatch_get_main_queue(), { 
                        completion(.Success(json))
                    })
                } catch {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(.Failure(DriftError.APIFailure))
                    })
                }
            }else if let error = error {
                dispatch_async(dispatch_get_main_queue(), {
                    completion(.Failure(error))
                })
            }else{
                dispatch_async(dispatch_get_main_queue(), {
                    completion(.Failure(DriftError.APIFailure))
                })
            }
            
            }.resume()
    }
    
    //Maps response to result T using ObjectMapper JSON parsing
    private class func mapResponse<T: Mappable>(result: Result<AnyObject>) -> Result<T> {
        
        switch result {
        case .Success(let res):
            if let json = res as? [String : AnyObject] {
                let response = Mapper<T>().map(json)     ///If initialisation is done in if let this can result in getting an object back when nil is returned - This is a bug in swift
                if let response = response {
                    return .Success(response)
                }
            }
            fallthrough
        default:
            return .Failure(DriftError.APIFailure)
        }
    }
    
    //Maps response to result [T] using ObjectMapper JSON parsing
    private class func mapResponse<T: Mappable>(result: Result<AnyObject>) -> Result<[T]> {
        
        switch result {
        case .Success(let res):
            if let json = res as? [[String: AnyObject]] {
                if let response: [T] = Mapper<T>().mapArray(json){
                    return .Success(response)
                }
            }
            fallthrough
        default:
            return .Failure(DriftError.APIFailure)
        }
    }
}

class URLStore{
    
    static let identifyURL = NSURL(string: "https://event.api.driftt.com/identify")!
    static let layerTokenURL = NSURL(string: "https://customer.api.driftt.com/layer/token")!
    static let tokenURL = NSURL(string: "https://customer.api.driftt.com/oauth/token")!
    class func embedURL(embedId: String, refresh: Int?) -> NSURL? {

        let refreshString = Int(NSDate().timeIntervalSince1970 % Double((refresh ?? 30000)))
        
        return NSURL(string: "https://js.driftt.com/embeds/\(refreshString)/\(embedId).json")
    }
    
    class func campaignUserURL(orgId: Int, authToken: String) -> NSURL? {
        return NSURL(string: "https://customer.api.driftt.com/organizations/\(orgId)/users?access_token=\(authToken)")
    }
        
    class func conversationsURL(endUserId: Int, authToken: String) -> NSURL? {
        return NSURL(string: "https://conversation.api.driftt.com/conversations/end_users/\(endUserId)?access_token=\(authToken)")
    }
    
    class func messagesURL(conversationId: Int, authToken: String) -> NSURL? {
        return NSURL(string: "https://conversation.api.driftt.com/conversations/\(conversationId)/messages?access_token=\(authToken)")
    }
    
    class func createConversationURL(authToken: String) -> NSURL? {
        return NSURL(string: "https://conversation.api.drift.com/messages?access_token=\(authToken)")
    }

    class func postAttachmentURL(authToken: String) -> NSURL? {
        return NSURL(string: "https://conversation.api.driftt.com/attachments?access_token=\(authToken)")
    }
    
    class func downloadAttachmentURL(attachmentId: Int, authToken: String) -> NSURL? {
        return NSURL(string: "https://conversation.api.driftt.com/attachments/\(attachmentId)/data?access_token=\(authToken)")
    }
    
    class func getAttachmentsURL(attachmentIds: [Int], authToken: String) -> NSURL? {
        var params = ""
        for id in attachmentIds{
            params += "&id=\(id)"
        }
        params += "&img_auto=compress"

        return NSURL(string: "https://conversation.api.driftt.com/attachments?access_token=\(authToken)\(params)")
    }
    
    class func usersURL(userId: Int, authToken: String) -> NSURL? {
        return NSURL(string: "https://customer.api.driftt.com/end_users/\(userId)?access_token=\(authToken)")
    }
}

///Result object for either Success with sucessfully parsed T
enum Result<T> {
    case Success(T)
    case Failure(ErrorType)
}


private enum HeaderField: String {
    case Accept = "Accept"
    case ContentType = "Content-Type"
}

private enum HeaderValue: String {
    case ApplicationJson = "application/json"
    case FormURLEncoded = "application/x-www-form-urlencoded"
}

///Request Object to encompase API Requests
class Request {
    
    enum Method: String {
        case POST = "POST"
        case GET = "GET"
        case OPTIONS = "OPTIONS"
    }
    
    enum DataType {
        case URL(params: [String: AnyObject])
        case JSON(json: [String: AnyObject])
        case FORM(json: [String: AnyObject])

        
        func appendToRequest(request:NSMutableURLRequest) -> NSMutableURLRequest {
            
            switch self {
                
            case .URL(let params):
                
                let url = NSURLComponents(URL: request.URL!, resolvingAgainstBaseURL: false)
                
                let queries = params.queryItems()
                
                url?.queryItems = queries
                
                request.URL = url?.URL
                
            case .JSON(let json):
                
                request.addValue(HeaderValue.ApplicationJson.rawValue, forHTTPHeaderField: HeaderField.Accept.rawValue)
                request.addValue(HeaderValue.ApplicationJson.rawValue, forHTTPHeaderField: HeaderField.ContentType.rawValue)
                
                do {
                    let jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted)
                    request.HTTPBody = jsonData
                } catch let error as NSError {
                    LoggerManager.log(error.localizedDescription)
                }
                
            case .FORM(let params):
                
                request.addValue(HeaderValue.FormURLEncoded.rawValue, forHTTPHeaderField: HeaderField.ContentType.rawValue)

                func query(parameters: [String: AnyObject]) -> String {
                    var components: [(String, String)] = []
                    
                    for key in parameters.keys.sort(<) {
                        let value = parameters[key]!
                        components += queryComponents(key, value)
                    }
                    
                    return (components.map { "\($0)=\($1)" } as [String]).joinWithSeparator("&")
                }

                if let URLComponents = NSURLComponents(URL: request.URL!, resolvingAgainstBaseURL: false) {
                    let percentEncodedQuery = (URLComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(params)
                    URLComponents.percentEncodedQuery = percentEncodedQuery
                    request.URL = URLComponents.URL
                }
            }
            
            return request
        }
    }
    
    var dataType:DataType?
    var method: Method = .GET
    var url: NSURL
    
    init(url: NSURL) {
        self.url = url
    }
    
    func setMethod(method: Method) -> Request {
        self.method = method
        return self
    }
    
    func setData(dataType: DataType) -> Request {
        self.dataType = dataType
        return self
    }
    
    func getRequest() -> NSURLRequest {
        
        var request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = method.rawValue
        
        if let dataType = dataType {
            request = dataType.appendToRequest(request)
        }
        
        return request
    }
}

/**
 Creates percent-escaped, URL encoded query string components from the given key-value pair using recursion.
 
 - parameter key:   The key of the query component.
 - parameter value: The value of the query component.
 
 - returns: The percent-escaped, URL encoded query string components.
 */
func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
    var components: [(String, String)] = []
    
    if let dictionary = value as? [String: AnyObject] {
        for (nestedKey, value) in dictionary {
            components += queryComponents("\(key)[\(nestedKey)]", value)
        }
    } else if let array = value as? [AnyObject] {
        for value in array {
            components += queryComponents("\(key)[]", value)
        }
    } else {
        components.append((escape(key), escape("\(value)")))
    }
    
    return components
}

func escape(string: String) -> String {
    let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
    let subDelimitersToEncode = "!$&'()*+,;="
    
    let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
    allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode + subDelimitersToEncode)
    
    var escaped = ""
    
    if #available(iOS 8.3, OSX 10.10, *) {
        escaped = string.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? string
    } else {
        let batchSize = 50
        var index = string.startIndex
        
        while index != string.endIndex {
            let startIndex = index
            let endIndex = index.advancedBy(batchSize, limit: string.endIndex)
            let range = startIndex..<endIndex
            
            let substring = string.substringWithRange(range)
            
            escaped += substring.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? substring
            
            index = endIndex
        }
    }
    
    return escaped
}

extension Dictionary {
    
    func queryItems() -> [NSURLQueryItem] {
        var queryItems: [NSURLQueryItem] = []
        for (key, value) in self {
            queryItems.append(NSURLQueryItem(name: String(key), value: String(value)))
        }
        return queryItems
    }
}
