//
//  RewardManager.swift
//  MonetLibrary
//
//  Created by Thang Huy Hoang on 9/2/25.
//

import Foundation
import GoogleMobileAds
class RewardManager: NSObject, ObservableObject {
    private let loader = RewardLoader.shared
    var currentAdShowing: GADRewardedAd? = nil
    var onAdDismiss:(()->Void)? = nil
    
    func loadAd(config: RewardConfig, remoteConfigKey: String) async -> GADRewardedAd? {
        //TODO
//        if !AdRemoteConfig.shared.bool(key: remoteConfigKey) {
//            return nil
//        }
        return await loader.loadAd(config: config)
    }
    
    func showAd(ad: GADRewardedAd, onEarnReward: (()->Void)? = nil, onAdDismiss: (()->Void)? = nil) {
        currentAdShowing = ad
        self.onAdDismiss = onAdDismiss
        ad.fullScreenContentDelegate = self
        ad.present(fromRootViewController: getRootViewController()) {
            onEarnReward?()
        }
        loader.removeCache(adUnitId: ad.adUnitID)
    }
    
    
    
}

extension RewardManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: any GADFullScreenPresentingAd) {
        onAdDismiss?()
    }
}
