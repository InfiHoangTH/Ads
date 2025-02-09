//
//  InterstitialLoader.swift
//  MonetLibrary
//
//  Created by Hoang on 4/2/25.
//

import Foundation
import GoogleMobileAds

class InterstitialLoader: ObservableObject{
    static let shared = InterstitialLoader()
    private init() {}
    @Published var isLoading: Bool =  false
    private var cachedAds: [String: GADInterstitialAd?] = [:]
    
    func loadInterstitial(config: InterstitialConfig) async -> GADInterstitialAd? {
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
                return ad
            }
        }
    }
    
    private func loadAds(id: String) async throws -> GADInterstitialAd {
        return try await withCheckedThrowingContinuation { continuation in
            let request = GADRequest()
            if cachedAds[id] != nil {
                continuation.resume(returning: cachedAds[id]!!)
            } else {
                GADInterstitialAd.load(withAdUnitID: id, request: request) { ad, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let ad = ad {
                        self.cachedAds[id] = ad
                        continuation.resume(returning: ad)
                    } else {
                        continuation.resume(throwing: NSError(domain: "AdError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load ad with unknown error"]))
                    }
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
                if ad != nil {
                    fastesAd = ad
                    group.cancelAll()
                    break
                }
                
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

            for i in 0..<(adUnitIDs.count - 1) {
                group.addTask {
                    let ad = try? await self.loadAds(id: adUnitIDs[i])
                    return (adUnitIDs[i], ad)
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

   
    func removeCache(adUnitId: String) {
        cachedAds[adUnitId] = nil
    }
    
    
    
}

