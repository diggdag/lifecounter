import UIKit
import GoogleMobileAds

class NativeAdTableViewCell2: UITableViewCell {

    // GADNativeAdView を storyboard 上に置いたものと接続
    @IBOutlet weak var nativeAdView: GADNativeAdView!

    // その中の subview も接続
    @IBOutlet weak var headlineLabel: UILabel!
//    @IBOutlet weak var advertiserLabel: UILabel!
//    @IBOutlet weak var callToActionButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var mediaContentView: GADMediaView!

    @IBOutlet weak var memo: UILabel!
    func bind(ad: GADNativeAd,memo:String) {
//        self.memo.text=memo//テスト時はこのコメントを外す
//        callToActionButton.titleLabel?.numberOfLines = 0
//        callToActionButton.titleLabel?.adjustsFontSizeToFitWidth = true
//        callToActionButton.titleLabel?.minimumScaleFactor = 0.8
        // GADNativeAdView に subview をマッピング
        nativeAdView.headlineView = headlineLabel
//        nativeAdView.advertiserView = advertiserLabel
        nativeAdView.advertiserView = nil
//        nativeAdView.callToActionView = callToActionButton
//        nativeAdView.iconView = iconImageView
        nativeAdView.mediaView = mediaContentView

        // データを代入
        headlineLabel.text = ad.headline
//        advertiserLabel.text = ad.advertiser
//        callToActionButton.setTitle(ad.callToAction, for: .normal)
//        callToActionButton.titleLabel?.adjustsFontSizeToFitWidth = true
//        callToActionButton.titleLabel?.minimumScaleFactor = 0.5
        iconImageView.image = ad.icon?.image
        mediaContentView.mediaContent = ad.mediaContent

        // Ad オブジェクトをバインド
        nativeAdView.nativeAd = ad
    }
}
