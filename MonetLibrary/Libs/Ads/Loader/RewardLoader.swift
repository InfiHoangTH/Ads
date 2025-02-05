//
//  RewardLoader.swift
//  MonetLibrary
//
//  Created by Hoang on 5/2/25.
//

import Foundation
import GoogleMobileAds

@MainActor
class RewardLoader: ObservableObject {
    @Published
    var isLoading: Bool = false

    func loadAd(config: RewardConfig) async->GADRewardedAd? {
        isLoading = true
        let reward = try? await loadAd(id: config.id)
        isLoading = false
        return reward
        
    }
    private func loadAd(id: String) async throws -> GADRewardedAd {
        let request = GADRequest()
        return try await
        withCheckedThrowingContinuation { continuetion in
            GADRewardedAd.load(withAdUnitID: id, request: request) { rewardAd, error in
                if let error = error {
                    continuetion.resume(throwing: error)
                } else if let ad = rewardAd {
                    continuetion.resume(returning: ad)
                } else {
                    continuetion.resume(throwing: NSError(domain: "AdError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load ad with unknow error" ]))
                }
            }
        }
        
    }
}
