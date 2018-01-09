import Foundation

class UniversityRequest: APIRequest {
    var method = RequestType.get
    var path = "search"
    var parameters: [String : String] = [:]

    init(name: String) {
        parameters["name"] = name
    }
}
