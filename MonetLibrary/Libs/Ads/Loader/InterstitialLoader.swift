//
//  InterstitialLoader.swift
//  MonetLibrary
//
//  Created by Hoang on 4/2/25.
//

import Foundation
import GoogleMobileAds
@MainActor
class InterstitialLoader: ObservableObject{
    @Published var isLoading: Bool =  false
    
    private func load(config: InterstitialConfig) async -> GADInterstitialAd? {
        isLoading = true
        let ids = config.adUnits
        if ids.isEmpty {
            fatalError("Ad unit id not config")
        }
        if ids.count == 1 {
            return try? await loadAds(id: ids[0])
        } else {
            switch config.loadType {
            case .fastest:
                let ad = try? await loadAdsFastest(ids: ids)
                isLoading = false
                return ad
            case .hfFastest:
                let ad = try? await loadAdsHfFastest(ids: ids)
                isLoading = false
                return ad
            case .prioritySync:
                let ad = try? await loadAdsPrioritySync(adUnitIDs: ids)
                isLoading = false
                return ad
            case .priorityAsync:
                let ad = try? await loadAdsPriorityAsync(adUnitIDs: ids)
                isLoading = false
                return try? await loadAdsPriorityAsync(adUnitIDs: ids)
            }
        }
    }
    
    private func loadAds(id: String) async throws -> GADInterstitialAd {
        let request = GADRequest()
        return try await withCheckedThrowingContinuation { continuation in
            GADInterstitialAd.load(withAdUnitID: id, request: request) {[weak self] ad, error in
                guard let self else {
                    return
                }
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    continuation.resume(returning: ad)
                } else {
                    continuation.resume(throwing: NSError(domain: "AdError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load ad with unknown error"]))
                }
            }
            
        }
    }

    private func loadAdsFastest(ids: [String]) async throws -> GADInterstitialAd {
        return try await withThrowingTaskGroup(of: GADInterstitialAd?.self) { group in
            
            var fastesAd: GADInterstitialAd?
            for id in ids {
                group.addTask {
                    try? await self.loadAds(id: id)
                }
            }
            for try await ad in group {
                fastesAd = ad
                group.cancelAll()
                break
            }
            if let fastesAd = fastesAd {
                return fastesAd
            } else {
                throw NSError(domain: "AdError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load ad with unknown error"])
            }
        }
        
    }
    
    private func loadAdsHfFastest(ids: [String]) async throws -> GADInterstitialAd {
            return try await withThrowingTaskGroup(of: GADInterstitialAd?.self) { group in
                var fastestAd: GADInterstitialAd?

                for i in 0..<ids.count - 1 {
                    group.addTask {
                        return try? await self.loadAds(id: ids[i])
                    }
                }

                for try await ad in group {
                    if let ad = ad {
                        fastestAd = ad
                        group.cancelAll()
                        break
                    }
                }

                if fastestAd == nil {
                    fastestAd = try await self.loadAds(id: ids.last!)
                }

                if let fastestAd = fastestAd {
                    return fastestAd
                } else {
                    throw NSError(domain: "AdError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load ad with unknown error"])
                }
            }
        }
    
    func loadAdsPrioritySync(adUnitIDs: [String]) async throws -> GADInterstitialAd {
        for adUnitID in adUnitIDs {
            do {
                let ad = try await loadAds(id: adUnitID)
                return ad // Nếu quảng cáo tải thành công, trả về ngay
            } catch {
                continue // Thử tiếp quảng cáo tiếp theo
            }
        }
        // Nếu tất cả quảng cáo đều thất bại, ném lỗi
        throw NSError(domain: "AdError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load ad with unknown error"])
    }
    
    func loadAdsPriorityAsync(adUnitIDs: [String]) async throws -> GADInterstitialAd {
        return try await withThrowingTaskGroup(of: (String, GADInterstitialAd?).self) { group in
            var results: [(String, GADInterstitialAd?)] = []

            // Chạy song song 4 quảng cáo đầu tiên
            for i in 0..<(adUnitIDs.count - 1) {
                group.addTask {
                    let ad = try? await self.loadAds(id: adUnitIDs[i]) // Load từng quảng cáo
                    return (adUnitIDs[i], ad) // Trả về tuple chứa ID quảng cáo và kết quả
                }
            }

            // Chờ tất cả quảng cáo hoàn thành và lưu kết quả
            for try await result in group {
                results.append(result)
            }

            // Sắp xếp kết quả theo thứ tự ban đầu của danh sách ID
            results.sort { lhs, rhs in
                guard let lhsIndex = adUnitIDs.firstIndex(of: lhs.0),
                      let rhsIndex = adUnitIDs.firstIndex(of: rhs.0) else { return false }
                return lhsIndex < rhsIndex
            }

            // Trả về quảng cáo đầu tiên load thành công theo thứ tự ưu tiên
            if let prioritizedAd = results.first(where: { $0.1 != nil })?.1 {
                return prioritizedAd
            }
            return try await self.loadAds(id: adUnitIDs[adUnitIDs.count - 1])
        }
    }

    /// Tải quảng cáo với một ID cụ thể (hàm async)
    private func loadAd(adUnitID: String) async throws -> GADInterstitialAd {
        return try await withCheckedThrowingContinuation { continuation in
            let request = GADRequest()
            GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    continuation.resume(returning: ad)
                } else {
                    continuation.resume(throwing: NSError(domain: "AdError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load ad with unknown error"]))
                }
            }
        }
    }
    
}

