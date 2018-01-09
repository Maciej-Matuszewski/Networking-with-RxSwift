import Foundation

public enum RequestType: String {
    case get = "GET"
    case post = "POST"
}

protocol APIRequest {
    var type: RequestType { get }
    var path: String { get }
    var parameters: [String : String] { get }
}

extension APIRequest {

    func request(baseURL: URL) -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            fatalError("Unable to create URL components")
        }

        components.queryItems = parameters.map {
            URLQueryItem(name: String($0), value: String($1))
        }

        guard let url = components.url else {
            fatalError("Could not get url")
        }

        var request = URLRequest(url: url)
        request.httpMethod = type.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

}
