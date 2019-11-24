import Foundation

protocol NetworkEngine {
    typealias Handler = (Data?, URLResponse?, Error?) -> Void
    
    func createRequest(for urlrequest: URLRequest, completionHandler: @escaping Handler) -> URLSessionDataTask
}

extension URLSession: NetworkEngine {
    typealias Handler = NetworkEngine.Handler
    
    func createRequest(for urlrequest: URLRequest, completionHandler: @escaping Handler) -> URLSessionDataTask {
        return dataTask(with: urlrequest, completionHandler: completionHandler)
    }
}
