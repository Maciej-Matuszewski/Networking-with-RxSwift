# Networking with RxSwift

*This days almost every application have some kind of server connections. In this small tutorial for beginners I will show you how to handle network communications using RxSwift. For the purposes of this guide we will create a small app that search universities using [Hipolabs API](http://universities.hipolabs.com/). The core of network communication will be based on `URLSession`. I assume that you know basics of iOS programing, so I will focus to explain only Rx parts of the project.*

## Prepare project
![](https://media.giphy.com/media/VGG8UY1nEl66Y/giphy.gif)

First step in our journey will be preparing the project, after creating it in Xcode, we need to add two external libraries:

* [RxSwift](https://github.com/ReactiveX/RxSwift)
* [RxCocoa](https://github.com/ReactiveX/RxSwift)

I used for that [Cocoapods](https://cocoapods.org), but feel free to import libraries via [Carthage](https://github.com/Carthage/Carthage) or manually. For Instructions head to [RxSwift repository page](https://github.com/ReactiveX/RxSwift#installation)

### Simple Layout

When our project is ready for coding we need to create place where received data will be presented. For this I created simple `UITableView` and `UISearchController` in main `ViewController` which should be embed in `UINavigationController`

Here you have code that do the work:
```
private let tableView = UITableView()
private let cellIdentifier = "cellIdentifier"

private let searchController: UISearchController = {
  let searchController = UISearchController(searchResultsController: nil)
  searchController.searchBar.placeholder = "Search for university"
  return searchController
}()

private func configureProperties() {
    tableView.register(TableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    navigationItem.searchController = searchController
    navigationItem.title = "University finder"
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationController?.navigationBar.prefersLargeTitles = true
}

private func configureLayout() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
    tableView.contentInset.bottom = view.safeAreaInsets.bottom
}
```
And here is the result:

![](https://media.giphy.com/media/xULW8KZqpGa3HAAG7C/giphy.gif)

## What we want to receive? How we want to receive it?

If our layout is ready we can try to handle some data from REST API. For that we will use [Hipolabs API](http://universities.hipolabs.com/).
We want to get informations about universities which names contain search phrase from our `UISearchController`.

### Example
Here you have example of request and response for finding universities with `middle` as name parameter.

|Request|Response|
|:--:|:--:|
|`http://universities.hipolabs.com/search?name=middle` | `[{"name": "Middlesex University", "domains": ["mdx.ac.uk"], "web_pages": ["http://www.mdx.ac.uk/"], "alpha_two_code": "GB", "state-province": null, "country": "United Kingdom"}, ...]`

Now when we know how API works we can create request and model objects.

### Model

For working on data that came from server we can use JSON dictionary like `[String: Any]`, but I prefer to create data model which is much clearer and easier to use. For purpose of receiving universities objects I created struct `UniversityModel`, which conform to `Codable` protocol and because of that we don't need to be bothered by parsing data, let's leave that to swift engine.

```
struct UniversityModel: Codable {
    let name: String
    let webPages: [String]?
    let country: String

    private enum CodingKeys: String, CodingKey {
        case name
        case webPages = "web_pages"
        case country
    }
}
```

### Requests

For making this more universal we need to create `APIRequest` protocol, so different requests could be handle by the same `APIClient`.

`APIRequest` class consists of two parts:

Protocol itself where are defined necessary properties:
```
protocol APIRequest {
    var method: RequestType { get }
    var path: String { get }
    var parameters: [String : String] { get }
}
```
Protocol extension that will create `URLRequest` from instance of `APIRequest`:
```
extension APIRequest {
    func request(with baseURL: URL) -> URLRequest {
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
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
```
I also created a small enum inside `APIRequest` class to improve declaring httpMethod:
```
public enum RequestType: String {
    case GET, POST
}
```

When `APIRequest` protocol is ready we can make real request specify for searching universities by names. For that we need to create another class inherited from `APIRequest` protocol where is defined method, endpoint path and parameters.

```
class UniversityRequest: APIRequest {
    var method = RequestType.GET
    var path = "search"
    var parameters = [:]

    init(name: String) {
        parameters["name"] = name
    }
}
```

*Ok, there was a lot of it, but where is this RxSwift?*

## Time for magic

![](https://media.giphy.com/media/12NUbkX6p4xOO4/giphy.gif)

Now it is time for the most important piece of this puzzle, part that will change our request for data from server. Now it is time for `APIClient`!

`APIClient` is a class where by using RxSwift `URLSession` task (created from previously prepared request) is converted to `Observable` that delivers already parsed model of data if only model is `Codable`.
```
class APIClient {
    private let baseURL = URL(string: "http://universities.hipolabs.com/")!

    func send<T: Codable>(apiRequest: APIRequest) -> Observable<T> {
        return Observable<T>.create { [unowned self] observer in
            let request = apiRequest.request(with: self.baseURL)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                do {
                    let model: T = try JSONDecoder().decode(T.self, from: data ?? Data())
                    observer.onNext(model)
                } catch let error {
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
```

## One ~~more~~ last thing...

After creating `APIClient` the last part is connecting everything together.

Result that we expect:

**Typing search phrase in search field** → **Instance of request created with search phrase** → **Array of models of university** → **Refreshed `UITableView` filled by new data** and all of that in **10 lines!!!**
```
searchController.searchBar.rx.text.asObservable()
  .map { ($0 ?? "").lowercased() }
  .map { UniversityRequest(name: $0) }
  .flatMap { request -> Observable<[UniversityModel]> in
    return self.apiClient.send(apiRequest: request)
  }
  .bind(to: tableView.rx.items(cellIdentifier: cellIdentifier)) { index, model, cell in
    cell.textLabel?.text = model.name
  }
  .disposed(by: disposeBag)
```
![](https://i.imgflip.com/22dq0i.jpg)

Please remember to import `RxSwift` and `RxCocoa` and create two variable:
```
private let apiClient = APIClient()
private let disposeBag = DisposeBag()
```

## Extra feature
![](https://i.imgflip.com/22dquz.jpg)

If you would like to present a website of university when user will tap on cell you can do this in 6 lines, by taking advantage from model and reactive binding.
```
tableView.rx.modelSelected(UniversityModel.self)
  .map { URL(string: $0.webPages?.first ?? "")! }
  .map { SFSafariViewController(url: $0) }
  .subscribe(onNext: { [weak self] safariViewController in
    self?.present(safariViewController, animated: true)
  })
  .disposed(by: disposeBag)
```

## **Final effect**

![](https://media.giphy.com/media/3ohjV5tmRenHpQmEYE/giphy.gif)

That is all for today. You can find the whole project at my [repository](https://github.com/Maciej-Matuszewski/Networking-with-RxSwift). I hope that you enjoyed.
