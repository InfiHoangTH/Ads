//
//  AdsManager.swift
//  MonetLibrary
//
//  Created by Hoang on 23/1/25.
//

import Foundation
import GoogleMobileAds
@MainActor
class AdsManager: ObservableObject {
    static let shared = AdsManager()
    let interstitialManager = InterstitialManager()
    private let rewardLoader = RewardLoader()
    
    init() {
        
    }
    
    
    func show(placementConfig: AdsPlacementConfig, action: @escaping() -> Void) {
        if defaultConfig.isPurchased {
            action()
            return
        }
        switch placementConfig.type {
        case .interstitial(let interstitialConfig):
            Task {
                let ad = await interstitialManager.loadAd(config: interstitialConfig, remoteConfigKey: placementConfig.activeConfigKey)
                if ad == nil {
                    action()
                } else {
                    interstitialManager.showAds(interstitialAd: ad!) {
                        print("😍 dismiss")
                        action()
                    }
                }
                
            }
            break
        case .reward(let rewardConfig):
            Task {
                let ad = await rewardLoader.loadAd(config: rewardConfig)
                ad?.present(fromRootViewController: getRootViewController(), userDidEarnRewardHandler: {
                    
                })
            }
            break
        default: break
        }
    }
    
    func getBannerConfig(placementConfig: AdsPlacementConfig) -> BannerConfig? {
        switch placementConfig.type {
        case .banner(let config):
            return config
        default: return nil
        }
    }
    
    
    
}


extension AdsManager  {

}
