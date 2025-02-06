//
//  AdsManager.swift
//  MonetLibrary
//
//  Created by Hoang on 23/1/25.
//

import Foundation
@MainActor
class AdsManager: ObservableObject {
    static let shared = AdsManager()
    private let interstitialLoader = InterstitialLoader()
    private let rewardLoader = RewardLoader()
    private let nativeLoader = NativeLoader()
    
    
    func show(placementConfig: AdsPlacementConfig, action: () -> Void) {
        if defaultConfig.isPurchased {
            action()
            return
        }
        switch placementConfig.type {
        case .interstitial(let interstitialConfig):
            Task {
                let ad = await interstitialLoader.load(config: interstitialConfig)
                ad?.present(fromRootViewController: getRootViewController()!)
                
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
    
    func getNativeAd(config: AdsPlacementConfig) async throws -> NativeAdView {
        return nativeLoader.loadNativeAd(id: config.)
    }
    
}
