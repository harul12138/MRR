import Foundation


public func summarize(text: String, completion: (([String]) -> Void)) {
    completion(text.summarize)
}



public func summarize(text: String, count: Int, completion: (([String]) -> Void)) {
    completion(text.summarize.slice(length: count))
}



public func summarize(text: String, compression: Float, completion: (([String]) -> Void)) {
    completion(text.summarize.slice(percent: compression))
}

public extension String {

    var summarize: [String] {
        return Summarizer(text: self).execute()
    }
}
