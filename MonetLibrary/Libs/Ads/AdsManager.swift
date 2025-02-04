//
//  AdsManager.swift
//  MonetLibrary
//
//  Created by Hoang on 23/1/25.
//

import Foundation

class AdsManager {
    static let shared = AdsManager()
    
    func show(placementConfig: AdsPlacementConfig, action: () -> Void) {
    
        if defaultConfig.isPurchased {
            action()
            return
        }
        switch placementConfig.type {
        case .banner(let bannerConfig):
            break
        case .native(let nativeConfig):
            break
        case .interstitial(let interstitialConfig):
            break
        case .reward(let rewardConfig):
            break
        }
    }
    
    
}
