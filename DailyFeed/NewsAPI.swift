

import Foundation

public typealias JSONDictionary = [String: AnyObject]

enum NewsAPI {
    
    case articles(source: String?)
    case sources(category: String?)
    
    static var baseURL = URLComponents(string: "https://newsapi.org")
     //static let apiToken = "53b8c0ba0ea24a199f790d660b73675f"
    static let apiToken = "f55c737dd64a463b8cbb9ee629f4ae25"
    
    //NewsAPI.org API Endpoints
    var url: URL? {
        switch self {
            
        case .articles(let source):
            let lSource = source ?? "abc-news-au"
            NewsAPI.baseURL?.path = "/v1/\(NewsAPI.articles(source: nil).jsonKey)"
            NewsAPI.baseURL?.queryItems = [URLQueryItem(name: "source", value: lSource),
                                          // URLQueryItem(name: "sortBy", value: "top"),
                                           URLQueryItem(name: "apiKey", value: NewsAPI.apiToken)]
            guard let url = NewsAPI.baseURL?.url else { return nil }
            return url
            
        case .sources(let category):
            let lCategory = category ?? ""
            NewsAPI.baseURL?.path = "/v1/\(NewsAPI.sources(category: nil).jsonKey)"
            NewsAPI.baseURL?.queryItems = [URLQueryItem(name: "category", value: lCategory), URLQueryItem(name: "language", value: "en")]
            guard let url = NewsAPI.baseURL?.url else { return nil }
            return url
        }
    }
    
    var jsonKey: String {
        switch self {
        case .articles:
            return "articles"
        case .sources:
            return "sources"
        }
    }
    
    //Fetch NewsSourceLogo from Cloudinary as news source logo is deprecated by newsapi.org
    
    static func fetchSourceNewsLogo(source: String) -> String {
        let sourceLogoUrl = "http://res.cloudinary.com/newsapi-logos/image/upload/v1492104667/\(source).png"
        return sourceLogoUrl
    }
    
    // Get News articles from /articles endpoint
    static func getNewsItems(_ source: String, completion: @escaping ([DailyFeedModel]?, Error?) -> Void) {
        
        guard let feedURL = NewsAPI.articles(source: source).url else { return }
        let baseUrlRequest = URLRequest(url: feedURL)
        let session = URLSession.shared
        
        session.dataTask(with: baseUrlRequest, completionHandler: { (data, response, error) in
            var newsItems = [DailyFeedModel]()
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, error)
                return
            }
            
            if let jsonData =  try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) {
                
                if let json = jsonData as? JSONDictionary, let jsonDict = json[NewsAPI.articles(source: nil).jsonKey] as? [JSONDictionary] {
                    newsItems = jsonDict.flatMap(DailyFeedModel.init)
                }
            }
            completion(newsItems, nil)
        }).resume()
    }
    
    // Get News source from /sources endpoint
    static func getNewsSource(_ category: String?, _ completion: @escaping ([DailySourceModel]?, Error?) -> Void) {
        
        guard let sourceURL = NewsAPI.sources(category: category).url else { return }
        
        let baseUrlRequest = URLRequest(url: sourceURL, cachePolicy: .returnCacheDataElseLoad)
        let session = URLSession.shared
        
        session.dataTask(with: baseUrlRequest, completionHandler: { (data, response, error) in
            var sourceItems = [DailySourceModel]()
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, error)
                return
            }
            
            if let jsonData =  try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) {
                
                if let json = jsonData as? JSONDictionary, let jsonDict = json[NewsAPI.sources(category: nil).jsonKey] as? [JSONDictionary] {
                    sourceItems = jsonDict.flatMap(DailySourceModel.init)
                }
            }
            completion(sourceItems, nil)
        }).resume()
    }
}
