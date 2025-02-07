//
//  NativeLoader.swift
//  MonetLibrary
//
//  Created by Hoang on 6/2/25.
//

import Foundation
import GoogleMobileAds

class NativeLoader: NSObject, ObservableObject, GADNativeAdLoaderDelegate {
    private var adContinuation: CheckedContinuation<GADNativeAd, Error>?
    private var loader:GADAdLoader?
    func loadNativeAd(id: String)  async throws -> GADNativeAd {
        return try await withCheckedThrowingContinuation {[weak self] continuation in
            guard let self else {return}
            self.adContinuation = continuation
            let adLoader = GADAdLoader(adUnitID: id, rootViewController: nil, adTypes: [.native], options: nil)
            loader = adLoader
            adLoader.delegate = self
            adLoader.load(GADRequest())
        }
    }
    
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        adContinuation?.resume(returning: nativeAd)
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: any Error) {
        adContinuation?.resume(throwing: error)
    }
    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        print("")
    }
}

@MainActor
class HFNativeLoader: ObservableObject {
    @Published var isLoading = false
    private let loader: NativeLoader = NativeLoader()
    
    func load(config: NativeConfig) async -> GADNativeAd? {
        isLoading = true
        let ids = config.adUnitIds
        if ids.isEmpty {
            fatalError("Ad unit id not config")
        }
        
        if ids.count ==  1 {
            return try? await loader.loadNativeAd(id: ids[0])
        } else {
            switch config.loadType {
            case .fastest:
                let ad = try? await loadAdFastest(adUnitIds: ids)
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
                let ad  = try? await loadAdsPriorityAsync(adUnitIDs: ids)
                isLoading = false
                return ad
            }
        }
    }
    
    private func loadAdFastest(adUnitIds: [String]) async throws->GADNativeAd {
        return try await withThrowingTaskGroup(of: GADNativeAd?.self) { [weak self] group in
            
            var fastestAD: GADNativeAd?
            for adUnitId in adUnitIds {
                group.addTask {
                    try? await self?.loader.loadNativeAd(id: adUnitId)
                }
            }
            
            for try await ad in group {
                if ad != nil {
                    fastestAD = ad
                    group.cancelAll()
                    break
                }
            }
            if let fastestAD = fastestAD {
                return fastestAD
            } else {
                throw NSError(domain: "AdError", code: 0, userInfo:[NSLocalizedDescriptionKey: "Failed to load ad with unknow error"])
            }
        }
    }
    
    
    private func loadAdsHfFastest(ids: [String]) async throws -> GADNativeAd {
        return try await withThrowingTaskGroup(of: GADNativeAd?.self) {[weak self] group in
            var fastestAd: GADNativeAd?
            
            for i in 0..<ids.count - 1 {
                group.addTask {
                    return try? await self?.loader.loadNativeAd(id: ids[i])
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
                fastestAd = try? await self?.loader.loadNativeAd(id: ids.last!)
            }
            
            if let fastestAd = fastestAd {
                return fastestAd
            } else {
                throw NSError(domain: "AdError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load ad with unknown error"])
            }
        }
    }
    
    
    func loadAdsPrioritySync(adUnitIDs: [String]) async throws -> GADNativeAd {
        for adUnitID in adUnitIDs {
            do {
                let ad = try await loader.loadNativeAd(id: adUnitID)
                return ad // Nếu quảng cáo tải thành công, trả về ngay
            } catch {
                continue // Thử tiếp quảng cáo tiếp theo
            }
        }
        // Nếu tất cả quảng cáo đều thất bại, ném lỗi
        throw NSError(domain: "AdError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load ad with unknown error"])
    }
    
    
    func loadAdsPriorityAsync(adUnitIDs: [String]) async throws -> GADNativeAd {
        return try await withThrowingTaskGroup(of: (String, GADNativeAd?).self) { group in
            var results: [(String, GADNativeAd?)] = []
            
            for i in 0..<(adUnitIDs.count - 1) {
                group.addTask {
                    let ad = try? await self.loader.loadNativeAd(id: adUnitIDs[i])
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
            return try await self.loader.loadNativeAd(id: adUnitIDs[adUnitIDs.count - 1])
        }
    }
}
