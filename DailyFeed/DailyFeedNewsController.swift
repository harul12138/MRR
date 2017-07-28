

import UIKit
import Lottie
import DZNEmptyDataSet

class DailyFeedNewsController: UICollectionViewController {

    // MARK: - Variable declaration

    var newsItems: [DailyFeedModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    var source: String {
        get {
            guard let defaultSource = UserDefaults(suiteName: "group.com.mmr.nfinder")?.string(forKey: "source") else {
                return "the-wall-street-journal"
            }

            return defaultSource
        }
        
        set {
           UserDefaults(suiteName: "group.com.mmr.nfinder")?.set(newValue, forKey: "source")
        }
    }

    let spinningActivityIndicator = TSSpinnerView()

    let refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.tintColor = .black
        return refresh
    }()
    
    let animationView =  LOTAnimationView(name: "Logo")
    
    var selectedIndexPath: IndexPath?

    // MARK: - IBOutlets

    @IBOutlet weak var toggleButton: UIButton!

    // MARK: - View Controller Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        //Setup UI
        setupUI()
        //Populate CollectionView Data
        loadNewsData(source)
        
        Reach().monitorReachabilityChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Setup UI
    func setupUI() {
        setupNavigationBar()
        setupCollectionView()
    }

    // MARK: - Setup navigationBar
    func setupNavigationBar() {
        animationView?.contentMode = .scaleAspectFill
        animationView?.isUserInteractionEnabled  = false
        animationView?.loopAnimation = true
        animationView?.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        let sourceMenuButton = UIButton(type: .custom)
        sourceMenuButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        sourceMenuButton.addSubview(animationView!)
        animationView?.play()
        sourceMenuButton.addTarget(self, action: #selector(sourceMenuButtonDidTap), for: .touchUpInside)
        navigationItem.titleView = sourceMenuButton
    }

    // MARK: - Setup CollectionView
    func setupCollectionView() {
        collectionView?.register(UINib(nibName: "DailyFeedItemCell", bundle: nil),
                                 forCellWithReuseIdentifier: "DailyFeedItemCell")
        collectionView?.register(UINib(nibName: "DailyFeedItemListCell", bundle: nil),
                                 forCellWithReuseIdentifier: "DailyFeedItemListCell")
        collectionView?.collectionViewLayout = DailySourceItemLayout()
        collectionView?.addSubview(refreshControl)
        refreshControl.addTarget(self,
                                 action: #selector(DailyFeedNewsController.refreshData(_:)),
                                 for: UIControlEvents.valueChanged)
        collectionView?.emptyDataSetDelegate = self
        collectionView?.emptyDataSetSource = self
    }

    // MARK: - Setup Spinner
    func setupSpinner() {
        spinningActivityIndicator.setupTSSpinnerView()
    }

    // MARK: - refresh news Source data
    func refreshData(_ sender: UIRefreshControl) {
        loadNewsData(self.source)
    }

    // MARK: - Load data from network
    func loadNewsData(_ source: String) {
        switch Reach().connectionStatus() {
        
        case .offline, .unknown:
            self.showError("Internet connection is offline", message: nil, handler: { _ in
                self.refreshControl.endRefreshing()
            })
            
        case .online(_):
            
            if !self.refreshControl.isRefreshing {
                setupSpinner()
            }
            
            spinningActivityIndicator.start()
            NewsAPI.getNewsItems(source) { (newsItem, error) in
                guard error == nil, let news = newsItem else {
                    DispatchQueue.main.async {
                        self.spinningActivityIndicator.stop()
                        self.refreshControl.endRefreshing()
                        self.showError(error?.localizedDescription ?? "")
                    }
                    return
                }
                self.newsItems = news
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                    self.spinningActivityIndicator.stop()
                }
            }
        }
    }
    
    deinit {
        collectionView?.delegate = nil
        collectionView?.dataSource = nil
    }

    // MARK: - Toggle Layout
    @IBAction func toggleArticlesLayout(_ sender: UIButton) {

        switch collectionView?.collectionViewLayout {
        case is DailySourceItemLayout:
            toggleButton.setImage(UIImage(named: "grid"), for: .normal)
            switchCollectionViewLayout(for: DailySourceItemListLayout())

        default:
            toggleButton.setImage(UIImage(named: "list"), for: .normal)
            switchCollectionViewLayout(for: DailySourceItemLayout())
        }
    }

    // Helper method for switching layouts and changing collectionview background color
    func switchCollectionViewLayout(for layout: UICollectionViewLayout) {
        collectionView?.collectionViewLayout.invalidateLayout()
        UIView.animate(withDuration: 0.03) {
            self.collectionView?.setCollectionViewLayout(layout, animated: false)
            self.collectionView?.reloadData()
        }
    }

    // MARK: - sourceMenuButton Action method

    func sourceMenuButtonDidTap() {
        if animationView?.isAnimationPlaying == .some(true) {
            animationView?.pause()
        }
        self.performSegue(withIdentifier: "newsSourceSegue", sender: self)
    }

    // MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newsDetailSegue" {
            if let vc = segue.destination as? NewsDetailViewController {
            guard let cell = sender as? UICollectionViewCell else { return }
            guard let indexpath = self.collectionView?.indexPath(for: cell) else { return }
            
                vc.receivedNewsItem = DailyFeedRealmModel.toDailyFeedRealmModel(from: newsItems[indexpath.row])
                vc.receivedItemNumber = indexpath.row + 1
                vc.receivedNewsSourceLogo = NewsAPI.fetchSourceNewsLogo(source: self.source)
            }
        }
    }

    // MARK: - Unwind from Source View Controller
    @IBAction func unwindToDailyNewsFeed(_ segue: UIStoryboardSegue) {
        if let sourceVC = segue.source as? NewsSourceViewController, let sourceId = sourceVC.selectedItem?.sid {
            let status = Reach().connectionStatus()
            switch status {
            case .unknown, .offline:
                self.showErrorWithDelay("Your Internet Connection is offline.")
            case .online(.wwan), .online(.wiFi):
                self.source = sourceId
                loadNewsData(source)
            }
        }
    }
}


extension DailyFeedNewsController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    // MARK: - DZNEmptyDataSet Delegate Methods
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Errors-No Content"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Please connect to Internet or try another source."
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "placeholder")
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}

