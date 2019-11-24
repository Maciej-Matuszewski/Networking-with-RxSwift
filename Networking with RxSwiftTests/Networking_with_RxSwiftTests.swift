import XCTest

@testable import Networking_with_RxSwift

class NetworkEngineMock: NetworkEngine {
    typealias Handler = NetworkEngine.Handler
    
    var requestURL: URLRequest?
    
    func createRequest(for urlrequest: URLRequest, completionHandler: @escaping Handler) -> URLSessionDataTask {
        requestURL = urlrequest
        let data = "www.baidu.com".data(using: .utf8)
        completionHandler(data, nil, nil)
        return URLSessionDataTask()
    }
}

class Networking_with_RxSwiftTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSendRequest() {
//        let engine = NetworkEngineMock()
//        let apiClient:APIClient = APIClient(engine: engine)
//
//        let request:APIRequest = UniversityRequest(name: "test")
//        apiClient.send(apiRequest: request)
    }

}
