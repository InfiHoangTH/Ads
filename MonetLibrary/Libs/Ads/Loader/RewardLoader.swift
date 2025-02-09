//
//  RewardLoader.swift
//  MonetLibrary
//
//  Created by Hoang on 5/2/25.
//

import Foundation
import GoogleMobileAds

class RewardLoader: ObservableObject {
    static let shared = RewardLoader()
    private var cachedAds: [String:GADRewardedAd] = [:]
    private init() {}
    func loadAd(config: RewardConfig) async->GADRewardedAd? {
        let reward = try? await loadAd(id: config.id)
        return reward
        
    }
    private func loadAd(id: String) async throws -> GADRewardedAd {
        let request = GADRequest()
        if let ad = cachedAds[id] {
            return ad
        } else {
            return try await
            withCheckedThrowingContinuation { continuetion in
                GADRewardedAd.load(withAdUnitID: id, request: request) {[weak self] rewardAd, error in
                    if let error = error {
                        continuetion.resume(throwing: error)
                    } else if let ad = rewardAd {
                        self?.cachedAds[id] = rewardAd
                        continuetion.resume(returning: ad)
                    } else {
                        continuetion.resume(throwing: NSError(domain: "AdError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load ad with unknow error" ]))
                    }
                }
            }
        }
    }
    
    func removeCache(adUnitId:String) {
        cachedAds[adUnitId] = nil
    }
}
