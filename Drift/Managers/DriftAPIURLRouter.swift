//
//  DriftAPIURLRouter.swift
//  Pods
//
//  Created by Eoin O'Connell on 29/05/2017.
//
//

import Alamofire

enum APIBase: String {
    case Customer = "https://customer.api.drift.com/"
    case Conversation = "https://conversation.api.drift.com/"
    case Conversation2 = "https://conversation2.api.drift.com/"
    case Messaging = "https://messaging.api.drift.com/"
    case Meetings = "https://meetings.api.drift.com/"
}


enum DriftRouter: URLRequestConvertible {
    
    case getEmbed(embedId: String, refreshRate: Int?)
    case postIdentify(params: [String: Any])
    case getSocketData(orgId: Int, accessToken: String)
    
    var request: (method: Alamofire.HTTPMethod, url: URL, parameters: [String: Any]?, encoding: ParameterEncoding){
        switch self {
        case .getEmbed(let embedId, let refreshRate):
            
            let refreshString = Int(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: Double((refreshRate ?? 30000))))

            return (.get, URL(string:"https://js.drift.com/embeds/\(refreshString)/\(embedId).json")!, nil, URLEncoding.default)
            
        case .postIdentify(let params):
            return (.post, URL(string: "https://event.api.drift.com/identify")!, params, JSONEncoding.default)
        case .getSocketData(let orgId, let accessToken):
            return (.post, URL(string:"https://\(orgId)-\(computeShardId(orgId: orgId)).chat.api.drift.com/api/auth")!, ["access_token": accessToken], JSONEncoding.default)
            
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        let encoding = request.encoding
        var req = try encoding.encode(urlRequest, with: request.parameters)
        
        req.url = URL(string: (req.url?.absoluteString.replacingOccurrences(of: "%5B%5D=", with: "="))!)
        
        let mutableReq = (req.urlRequest! as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        
        return mutableReq as URLRequest
    }
    
    func computeShardId(orgId: Int) -> Int{
        return orgId % 50 //WS_NUM_SHARDS
    }
    
}

enum DriftCustomerRouter: URLRequestConvertible {
    
    case getAuth(email: String?, userId: String, userJwt:String?, redirectURL: String, orgId: Int, clientId: String)
    case getUser(orgId: Int, userId: Int64)
    case getEndUser(endUserId: Int64)
    
    var request: (method: Alamofire.HTTPMethod, path: String, parameters: [String: Any]?, encoding: ParameterEncoding){
        switch self {
        case .getAuth(let email, let userId, let userJwt, let redirectURL, let orgId, let clientId):
            
             var params: [String : Any] = [
                "org_id": orgId,
                "user_id": userId,
                "grant_type": "sdk",
                "redirect_uri":redirectURL,
                "client_id": clientId
            ]
             
             if let email = email {
                params["email"] = email
             }
            
            if let userJwt = userJwt {
                params["jwt"] = userJwt
            }
            
            return (.post, "oauth/token", params, URLEncoding.default)
        case .getUser(let orgId, let userId):
            
            let params: [String: Any] =
                [   "avatar_w": 102,
                    "avatar_h": 102,
                    "avatar_fit": "1",
                    "userId": userId
            ]
            
            return (.get, "organizations/\(orgId)/users", params, URLEncoding.default)
        case .getEndUser(let endUserId):
            return (.get, "end_users/\(endUserId)", nil, URLEncoding.default)
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: APIBase.Customer.rawValue)
        
        if let accessToken = DriftDataStore.sharedInstance.auth?.accessToken{
            let authItem = URLQueryItem(name: "access_token", value: accessToken)
            components?.queryItems = [authItem]
        }
        
        var urlRequest = URLRequest(url: (components?.url!.appendingPathComponent(request.path))!)
        urlRequest.httpMethod = request.method.rawValue
        let encoding = request.encoding
        var req = try encoding.encode(urlRequest, with: request.parameters)
        
        req.url = URL(string: (req.url?.absoluteString.replacingOccurrences(of: "%5B%5D=", with: "="))!)
        
        return req
    }
    
}

enum DriftConversationRouter: URLRequestConvertible {
        
    case getEnrichedConversationsForEndUser(endUserId: Int64)
    case getMessagesForConversation(conversationId: Int64)
        
    var request: (method: Alamofire.HTTPMethod, path: String, parameters: [String: Any]?, encoding: ParameterEncoding){
        switch self {
        case .getEnrichedConversationsForEndUser(let endUserId):
            return (.get, "conversations/end_users/\(endUserId)/extra", nil, URLEncoding.default)
        case .getMessagesForConversation(let conversationId):
            return (.get, "conversations/\(conversationId)/messages", nil, URLEncoding.default)
        }
    }
    
    
    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: APIBase.Conversation.rawValue)
        if let accessToken = DriftDataStore.sharedInstance.auth?.accessToken{
            let authItem = URLQueryItem(name: "access_token", value: accessToken)
            components?.queryItems = [authItem]
        }
        var urlRequest = URLRequest(url: (components?.url!.appendingPathComponent(request.path))!)
        urlRequest.httpMethod = request.method.rawValue
        let encoding = request.encoding
        var req = try encoding.encode(urlRequest, with: request.parameters)
        
        req.url = URL(string: (req.url?.absoluteString.replacingOccurrences(of: "%5B%5D=", with: "="))!)
        
        return req
    }
    
}

enum DriftConversation2Router: URLRequestConvertible {
    
    case markMessageAsRead(messageId: Int64)
    case markConversationAsRead(messageId: Int64)
    
    var request: (method: Alamofire.HTTPMethod, path: String, parameters: [String: Any]?, encoding: ParameterEncoding){
        switch self {
        case .markMessageAsRead(let messageId):
            return (.post, "messages/\(messageId)/read", nil, URLEncoding.default)
        case .markConversationAsRead(let messageId):
            return (.post, "messages/\(messageId)/read-until", nil, URLEncoding.default)
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(string: APIBase.Conversation.rawValue)
        if let accessToken = DriftDataStore.sharedInstance.auth?.accessToken{
            let authItem = URLQueryItem(name: "access_token", value: accessToken)
            components?.queryItems = [authItem]
        }
        var urlRequest = URLRequest(url: (components?.url!.appendingPathComponent(request.path))!)
        urlRequest.httpMethod = request.method.rawValue
        let encoding = request.encoding
        var req = try encoding.encode(urlRequest, with: request.parameters)
        
        req.url = URL(string: (req.url?.absoluteString.replacingOccurrences(of: "%5B%5D=", with: "="))!)

        return req
    }
    
}

enum DriftMessagingRouter: URLRequestConvertible {
    case createConversation(data: [String: Any])
    case postMessageToConversation(conversationId: Int64, message: [String: Any])
    
    var request: (method: Alamofire.HTTPMethod, path: String, parameters: [String: Any]?, encoding: ParameterEncoding){
        switch self {
        case .createConversation(let data):
            return (.post, "messages", data, JSONEncoding.default)
        case .postMessageToConversation(let conversationId, let json):
            return (.post, "conversations/\(conversationId)/messages", json, JSONEncoding.default)
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        
        var components = URLComponents(string: APIBase.Messaging.rawValue)
        if let accessToken = DriftDataStore.sharedInstance.auth?.accessToken{
            let authItem = URLQueryItem(name: "access_token", value: accessToken)
            components?.queryItems = [authItem]
        }
        var urlRequest = URLRequest(url: (components?.url!.appendingPathComponent(request.path))!)
        urlRequest.httpMethod = request.method.rawValue
        let encoding = request.encoding
        var req = try encoding.encode(urlRequest, with: request.parameters)
        
        req.url = URL(string: (req.url?.absoluteString.replacingOccurrences(of: "%5B%5D=", with: "="))!)
        
        return req
    }
}

enum DriftMeetingRouter: URLRequestConvertible {
    case getUserAvailability(userId: Int64)
    case scheduleMeeting(userId: Int64, conversationId: Int64, timestamp: Double)
    
    var request: (method: Alamofire.HTTPMethod, path: String, parameters: [String: Any]?, encoding: ParameterEncoding){
        switch self {
        case .getUserAvailability(let userId):
            return (.get, "scheduling/\(userId)/availability", nil, URLEncoding.default)
        case .scheduleMeeting(let userId, let conversationId, let timestamp):
            return (.post, "scheduling/\(userId)/schedule", nil, ScheduleEncoding(conversationId: conversationId, timestamp: timestamp))
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        
        var components = URLComponents(string: APIBase.Meetings.rawValue)
        if let accessToken = DriftDataStore.sharedInstance.auth?.accessToken{
            let authItem = URLQueryItem(name: "access_token", value: accessToken)
            components?.queryItems = [authItem]
        }
        var urlRequest = URLRequest(url: (components?.url!.appendingPathComponent(request.path))!)
        urlRequest.httpMethod = request.method.rawValue
        let encoding = request.encoding
        var req = try encoding.encode(urlRequest, with: request.parameters)
        
        req.url = URL(string: (req.url?.absoluteString.replacingOccurrences(of: "%5B%5D=", with: "="))!)
        
        return req
    }
}


struct ScheduleEncoding: ParameterEncoding {
    private let timestamp: Double
    private let conversationId: Int64
    init(conversationId: Int64, timestamp:Double) {
        self.timestamp = timestamp
        self.conversationId = conversationId
    }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
    
        let data = "\(timestamp)".data(using: .utf8)
        
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest.httpBody = data
        
        let req = try URLEncoding.queryString.encode(urlRequest, with: ["conversationId": conversationId])
        
        return req
    }
}
