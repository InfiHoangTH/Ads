//
//  NativeAdView.swift
//  MonetLibrary
//
//  Created by Hoang on 6/2/25.
//

import Foundation
import GoogleMobileAds
import SwiftUI

struct NativeAdView: UIViewRepresentable {
    let nativeAd: GADNativeAd

    func makeUIView(context: Context)->GADNativeAdView {
        return Bundle.main.loadNibNamed("NativeAdViewRepresentable01", owner: nil)?.first as! GADNativeAdView
    }
    
    func updateUIView(_ nativeAdView: GADNativeAdView, context: Context) {
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        let headerLabel = nativeAdView.headlineView as? UILabel
        headerLabel?.text = nativeAd.headline
        headerLabel?.numberOfLines = 2
        
        let bodyLabel = nativeAdView.bodyView as? UILabel
        bodyLabel?.text = nativeAd.body
        bodyLabel?.numberOfLines = 2
        
        let storeLabel = nativeAdView.storeView as? UILabel
        storeLabel?.text = nativeAd.store
        
        let priceLabel = nativeAdView.priceView as? UILabel
        priceLabel?.text = nativeAd.price
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(from: nativeAd.starRating)
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        
    }
    
    
    private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        if rating >= 5 {
            return UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            return UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5")
        } else {
            return nil
        }
    }
}
