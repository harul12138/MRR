

import UIKit

class DailyFeedItemListCell: UICollectionViewCell {
    
    @IBOutlet weak var newsArticleImageView: TSImageView! {
        didSet {
            newsArticleImageView.layer.cornerRadius = 5.0
            newsArticleImageView.layer.borderColor = UIColor(white: 0.1, alpha: 0.1).cgColor
            newsArticleImageView.layer.borderWidth = 0.5
            newsArticleImageView.clipsToBounds = true
        }
    }

    @IBOutlet weak var newsArticleTitleLabel: UILabel!
    @IBOutlet weak var newsArticleAuthorLabel: UILabel!
    @IBOutlet weak var newsArticleTimeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with newsitem: DailyFeedModel) {
        self.newsArticleTitleLabel.text = newsitem.title
        self.newsArticleAuthorLabel.text = newsitem.author
        self.newsArticleTimeLabel.text = newsitem.publishedAt.dateFromTimestamp?.relativelyFormatted(short: true)
        self.newsArticleImageView.downloadedFromLink(newsitem.urlToImage)
    }
}
