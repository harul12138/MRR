
import UIKit

// MARK: - CollectionView Delegate Methods
extension DailyFeedNewsController: UICollectionViewDelegateFlowLayout {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {

            return self.newsItems.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        collectionView.performBatchUpdates(nil, completion: nil)
        let cell = collectionView.cellForItem(at: indexPath)
        self.performSegue(withIdentifier: "newsDetailSegue", sender: cell)

    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let gridCell = collectionView.dequeueReusableCell(withReuseIdentifier: "DailyFeedItemCell",
                                                          for: indexPath) as? DailyFeedItemCell
        let listCell = collectionView.dequeueReusableCell(withReuseIdentifier: "DailyFeedItemListCell",
                                                          for: indexPath) as? DailyFeedItemListCell

        switch collectionView.collectionViewLayout {

        case is DailySourceItemListLayout:
                listCell?.configure(with: newsItems[indexPath.row])
                return listCell!

        default:
                gridCell?.configure(with: newsItems[indexPath.row])
                return gridCell!
        }
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {

        switch kind {

        case UICollectionElementKindSectionHeader:

            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: "newsHeaderView",
                                                                             for: indexPath) as? NewHeaderCollectionReusableView
            headerView?.newSourceImageView.downloadedFromLink(NewsAPI.fetchSourceNewsLogo(source: self.source))
            headerView?.layer.masksToBounds = true
            return headerView!

        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: "newsFooterView",
                                                                             for: indexPath)

            return footerView

        default:

            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height / 8)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
            return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height / 10)
    }
}
