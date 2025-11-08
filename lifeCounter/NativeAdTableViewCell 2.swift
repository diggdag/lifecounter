import UIKit
import GoogleMobileAds

final class NativeAdTableViewCell2: UITableViewCell {

    @IBOutlet weak var nativeAdView: GADNativeAdView!
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var mediaContentView: GADMediaView!
    @IBOutlet weak var memo: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Storyboard で既に contentView 配下に置いている想定。二重 add はしない
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false

        // 必ず nativeAdView の内側に収める
        mediaContentView.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        mediaContentView.contentMode = .scaleAspectFill
        mediaContentView.clipsToBounds = true

        // セルが小さく圧縮しないように
        nativeAdView.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.clipsToBounds = true
        nativeAdView.clipsToBounds = true
        selectionStyle = .none

        NSLayoutConstraint.activate([
            // media は動画対策で最低 120pt 四方
            mediaContentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            mediaContentView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),

            // nativeAdView の内側にガード（外へ出ない）
            mediaContentView.topAnchor.constraint(greaterThanOrEqualTo: nativeAdView.topAnchor, constant: 8),
            mediaContentView.leadingAnchor.constraint(greaterThanOrEqualTo: nativeAdView.leadingAnchor, constant: 16),
            mediaContentView.trailingAnchor.constraint(lessThanOrEqualTo: nativeAdView.trailingAnchor, constant: -16),
            mediaContentView.bottomAnchor.constraint(lessThanOrEqualTo: nativeAdView.bottomAnchor, constant: -8),

            // 見出しも内側に
            headlineLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nativeAdView.leadingAnchor, constant: 16),
            headlineLabel.trailingAnchor.constraint(lessThanOrEqualTo: nativeAdView.trailingAnchor, constant: -16),
            headlineLabel.topAnchor.constraint(greaterThanOrEqualTo: nativeAdView.topAnchor, constant: 8),
            headlineLabel.bottomAnchor.constraint(lessThanOrEqualTo: nativeAdView.bottomAnchor, constant: -8),
        ])
    }

    func bind(ad: GADNativeAd, memo: String) {
        // マッピングは『nativeAdView の直下の子ビュー』だけ
        nativeAdView.headlineView = headlineLabel
        nativeAdView.mediaView    = mediaContentView

        // アイコンはまず無効化（誤検知回避）。使うなら nativeAdView 内に十分なサイズで置く
        nativeAdView.iconView     = nil
        iconImageView.image       = nil
        iconImageView.isHidden    = true

        // データ
        headlineLabel.text = ad.headline
//        self.memo.text     = memo
        self.memo.text     = "[PR]"
        mediaContentView.mediaContent = ad.mediaContent

        // 最後にバインド
        nativeAdView.nativeAd = ad

        // レイアウトを確定
        layoutIfNeeded()
    }
}
