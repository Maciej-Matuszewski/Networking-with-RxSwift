import Foundation
import RxSwift

class APIClient {
    
    private let engine: NetworkEngine
    private let baseURL = URL(string: "http://universities.hipolabs.com/")!

    init(engine: NetworkEngine = URLSession.shared) {
        self.engine = engine
    }
    
    func send<T: Codable>(apiRequest: APIRequest) -> Observable<T> {
        return Observable<T>.create { [unowned self] observer in
            let request = apiRequest.request(with: self.baseURL)
            let task = self.engine.createRequest(for: request, completionHandler: { (data, response, error) in
                do {
                    let model: T = try JSONDecoder().decode(T.self, from: data ?? Data())
                    observer.onNext(model)
                } catch let error {
                    observer.onError(error)
                }
                observer.onCompleted()
            })
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
