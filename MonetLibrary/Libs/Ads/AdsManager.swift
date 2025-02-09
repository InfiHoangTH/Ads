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
    private init() {}
    @Published var isLoadingAd = false
    private let interstitialManager = InterstitialManager()
    private let rewardManager = RewardManager()
    internal var cachedNativeAds:[String: GADNativeAd] = [:]
    
    
    func removeCachedNative(adUnitId: String) {
        cachedNativeAds[adUnitId] = nil
    }
    
    func show(placementConfig: AdsPlacementConfig, action: @escaping() -> Void) {
        if defaultConfig.isPurchased {
            action()
            return
        }
        switch placementConfig.type {
        case .interstitial(let interstitialConfig):
            Task {
                isLoadingAd = true
                let ad = await interstitialManager.loadAd(config: interstitialConfig, remoteConfigKey: placementConfig.activeConfigKey)
                isLoadingAd = false
                if ad == nil {
                    action()
                } else {
                    interstitialManager.showAds(interstitialAd: ad!) {[weak self] in
                        action()
                        guard let self else {return}
                        if placementConfig.needPreload {
                            Task {
                                await self.interstitialManager.loadAd(config: interstitialConfig, remoteConfigKey: placementConfig.activeConfigKey)
                            }
                        }
                    }
                }
                
            }
            break
        case .reward(let rewardConfig):
            Task {
                isLoadingAd = true
                let ad = await rewardManager.loadAd(config: rewardConfig, remoteConfigKey: placementConfig.activeConfigKey)
                isLoadingAd = false
                guard  let ad = ad else {
                    return
                }
                rewardManager.showAd(ad: ad) {
                    action()
                } onAdDismiss: {[weak self] in
                    guard let self else {return}
                    if placementConfig.needPreload {
                        Task {
                            await self.rewardManager.loadAd(config: rewardConfig , remoteConfigKey: placementConfig.activeConfigKey)
                        }
                    }
                }
                
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
