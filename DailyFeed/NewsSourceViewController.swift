

import UIKit
import DZNEmptyDataSet

class NewsSourceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    // MARK: - IBOutlets
    @IBOutlet weak var sourceTableView: UITableView!
    
    @IBOutlet weak var categoryButton: UIBarButtonItem!
    
    // MARK: - Variable declaration
    var sourceItems: [DailySourceModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.sourceTableView.reloadSections([0], with: .automatic)
                self.setupSpinner(hidden: true)
            }
        }
    }
    
    var filteredSourceItems: [DailySourceModel] = [] {
        didSet {
            self.sourceTableView.reloadSections([0], with: .automatic)
        }
    }
    
    var selectedItem: DailySourceModel?

    var categories: [String] = []

    var resultsSearchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.dimsBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        controller.searchBar.placeholder = "Search sources category..."
        controller.searchBar.searchBarStyle = .minimal
        controller.searchBar.tintColor = .gray
        controller.searchBar.sizeToFit()
        return controller
    }()
    
    let spinningActivityIndicator = TSSpinnerView()
    
    // MARK: - ViewController Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup UI
        setupUI()

        //Populate TableView Data
        loadSourceData(nil)
        //setup TableView
        setupTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resultsSearchController.delegate = nil
        resultsSearchController.searchBar.delegate = nil
    }

    // MARK: - Setup UI
    func setupUI() {
        
        setupSearch()
        
    }

    // MARK: - Setup SearchBar
    func setupSearch() {
        resultsSearchController.searchResultsUpdater = self
        navigationItem.titleView = resultsSearchController.searchBar
        definesPresentationContext = true
    }

    // MARK: - Setup TableView
    func setupTableView() {
        sourceTableView.register(UINib(nibName: "DailySourceItemCell",
                                       bundle: nil),
                                 forCellReuseIdentifier: "DailySourceItemCell")
        sourceTableView.tableFooterView = UIView()
    }

    // MARK: - Setup Spinner
    func setupSpinner(hidden: Bool) {
        spinningActivityIndicator.containerView.isHidden = hidden
        if !hidden {
            spinningActivityIndicator.setupTSSpinnerView()
            spinningActivityIndicator.start()
        } else {
            spinningActivityIndicator.stop()
        }
    }
    
    deinit {
        self.sourceTableView.delegate = nil
        self.sourceTableView.dataSource = nil
    }

    // MARK: - Show News Categories

    @IBAction func presentCategories(_ sender: Any) {
        let categoryActivityVC = UIAlertController(title: "NEWS Category",
                                                   message: nil,
                                                   preferredStyle: .actionSheet)

        let cancelButton = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
        
        _ = categories.map {
            let categoryButton = UIAlertAction(title: $0, style: .default, handler: { action in
                if let category = action.title {
                    self.loadSourceData(category)
                }
            })
            categoryActivityVC.addAction(categoryButton)
        }
        categoryActivityVC.addAction(cancelButton)
        self.present(categoryActivityVC, animated: true, completion: nil)
    }

    // MARK: - Load data from network
    func loadSourceData(_ category: String?) {
        setupSpinner(hidden: false)
        NewsAPI.getNewsSource(category) { (newsItem, error) in
            
            guard error == nil, let news = newsItem else {
                DispatchQueue.main.async {
                    self.setupSpinner(hidden: true)
                    self.showError(error?.localizedDescription ?? "") { _ in
                        self.dismiss(animated: true, completion: nil)
                    }
                }
                return
            }
            self.sourceItems = news
            
            // The code below helps in persisting category items till the view controller is de-allocated
            if category == nil {
                self.categories = Array(Set(news.map { $0.category }))
            }
        }
    }

    // MARK: - Status Bar Color and switching actions
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden ?? false
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    // MARK: - TableView Delegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.resultsSearchController.isActive {
            return self.filteredSourceItems.count + 1
        } else {
            return self.sourceItems.count + 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DailySourceItemCell",
                                                 for: indexPath) as? DailySourceItemCell

        if indexPath.row == 0 { return DailySourceItemCell() }
        if self.resultsSearchController.isActive {
            cell?.sourceImageView.downloadedFromLink(NewsAPI.fetchSourceNewsLogo(source: filteredSourceItems[indexPath.row - 1].sid))
        } else {
            cell?.sourceImageView.downloadedFromLink(NewsAPI.fetchSourceNewsLogo(source: sourceItems[indexPath.row - 1].sid))
        }
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.resultsSearchController.isActive {
            self.selectedItem = filteredSourceItems[indexPath.row - 1]
        } else {
            self.selectedItem = sourceItems[indexPath.row - 1]
        }

        self.performSegue(withIdentifier: "sourceUnwindSegue", sender: self)
    }
    
  
    // MARK: - SearchBar Delegate

    func updateSearchResults(for searchController: UISearchController) {

        filteredSourceItems.removeAll(keepingCapacity: false)

        if let searchString = searchController.searchBar.text {
            let searchResults = sourceItems.filter { $0.name.lowercased().contains(searchString.lowercased()) }
            filteredSourceItems = searchResults
        }
    }
}
