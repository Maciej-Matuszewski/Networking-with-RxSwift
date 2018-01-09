import Foundation

struct UniversityModel: Codable {
    let name: String
    let domains: [String]?
    let webPages: [String]?
    let country: String

    private enum CodingKeys: String, CodingKey {
        case name
        case domains
        case webPages = "web_pages"
        case country
    }

    var description: String {
        get {
            if let webPage = webPages?.first {
                return "\(country) • \(webPage)"
            } else {
                return country
            }
        }
    }
}
