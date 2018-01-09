import UIKit
import RxSwift
import RxCocoa
import SafariServices

class ViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let tableView = UITableView()
    private let cellIdentifier = "cellIdentifier"
    private var items: Variable<[UniversityModel]> = Variable([])
    private let apiClient = APIClient()

    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search for university"
        return searchController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureLayout()
        configureReactiveBinding()
    }

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

    private func configureReactiveBinding() {
        items.asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: cellIdentifier)) { index, model, cell in
                cell.textLabel?.text = model.name
                cell.detailTextLabel?.text = model.description
                cell.textLabel?.adjustsFontSizeToFitWidth = true
            }
            .disposed(by: disposeBag)

        searchController.searchBar.rx.text.asObservable()
            .throttle(1.0, latest: true, scheduler: MainScheduler.instance)
            .map { text -> String in
                return (text ?? "").lowercased()
            }
            .flatMap{ searchText -> Observable<[UniversityModel]> in
                return self.apiClient.send(apiRequest: UniversityRequest(name: searchText))
            }
            .bind(to: self.items)
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(UniversityModel.self)
            .map { model -> URL in
                return URL(string: model.webPages?.first ?? "")!
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] url in
                let safariViewController = SFSafariViewController(url: url)
                self?.present(safariViewController, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
