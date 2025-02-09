//
//  InterstitialManager.swift
//  MonetLibrary
//
//  Created by Hoang on 7/2/25.
//

import Foundation
import GoogleMobileAds

class InterstitialManager:NSObject, ObservableObject {
    private let loader = InterstitialLoader.shared
    var currentAdShowing: GADInterstitialAd? = nil
    private var onAdDismiss: (()->Void)? = nil
    
    func loadAd(config: InterstitialConfig, remoteConfigKey: String) async -> GADInterstitialAd? {
        //TODO:
//        if !AdRemoteConfig.shared.bool(key: remoteConfigKey) {
//            return nil
//        }
        let ad  = await loader.loadInterstitial(config: config)
        return ad
    }
    
    func showAds(interstitialAd: GADInterstitialAd, onAdDismiss: (()->Void)? = nil) {
        self.onAdDismiss = onAdDismiss
        currentAdShowing = interstitialAd
        interstitialAd.fullScreenContentDelegate = self
        interstitialAd.present(fromRootViewController: getRootViewController())
        loader.removeCache(adUnitId: interstitialAd.adUnitID)
    }
    
    func loadAndShowAds(config: InterstitialConfig, remoteConfigKey: String ,onAdDismiss: (()->Void)? = nil) {
        Task {
            if let ad  = await loadAd(config: config, remoteConfigKey: remoteConfigKey) {
                showAds(interstitialAd: ad, onAdDismiss: onAdDismiss)
            } else {
                onAdDismiss?()
            }
            
        }
    }
}

extension InterstitialManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: any GADFullScreenPresentingAd) {
        onAdDismiss?()
    }
}
