//
//  BannerAdView.swift
//  MonetLibrary
//
//  Created by Hoang on 5/2/25.
//
import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let bannerConifg: BannerConfig
    let adUnitIDs: [String]
    let loadType: LoadType
    init(config: BannerConfig) {
        bannerConifg = config
        adUnitIDs = config.ids
        loadType = config.loadType
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)
        context.coordinator.containerView = containerView
        switch loadType {
        case .fastest:
            context.coordinator.fastestLoad(adUnitIDs)
        case .hfFastest:
            context.coordinator.hfFastestLoad(adUnitIDs)
        case .prioritySync:
            context.coordinator.prioritySyncLoad(adUnitIDs)
        case .priorityAsync:
            context.coordinator.priorityAsyncLoad(adUnitIDs)
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, GADBannerViewDelegate {
        let parent: BannerAdView
        
        var containerView: UIView?
        
        var bannerViews: [GADBannerView] = []
        
        var hasDisplayedBanner: Bool = false
        
        var finishedCount = 0
        
        init(_ parent: BannerAdView) {
            self.parent = parent
        }
        
        func fastestLoad(_ adUnitIDs: [String]) {
            guard !adUnitIDs.isEmpty else { return }
            
            for adUnitID in adUnitIDs {
                let bannerView = createBannerView(adUnitID: adUnitID)
                bannerViews.append(bannerView)
                bannerView.load(GADRequest())
            }
        }
        
    
        func hfFastestLoad(_ adUnitIDs: [String]) {
            guard !adUnitIDs.isEmpty else { return }
            
            if adUnitIDs.count == 1 {
                let bannerView = createBannerView(adUnitID: adUnitIDs[0])
                bannerViews.append(bannerView)
                bannerView.load(GADRequest())
                return
            }
            
            let firstIDs = Array(adUnitIDs.dropLast())
            
            for adUnitID in firstIDs {
                let bannerView = createBannerView(adUnitID: adUnitID)
                bannerViews.append(bannerView)
                bannerView.load(GADRequest())
            }
        }
        
        func prioritySyncLoad(_ adUnitIDs: [String]) {
            guard !adUnitIDs.isEmpty else { return }
            loadBannerSequential(adUnitIDs, index: 0)
        }
        
        private func loadBannerSequential(_ adUnitIDs: [String], index: Int) {
            if index >= adUnitIDs.count {
                return
            }
            
            let bannerView = createBannerView(adUnitID: adUnitIDs[index])
            bannerView.tag = index
            bannerViews.append(bannerView)
            bannerView.load(GADRequest())
        }
    
        func priorityAsyncLoad(_ adUnitIDs: [String]) {
            guard !adUnitIDs.isEmpty else { return }
            
            if adUnitIDs.count == 1 {
                let bannerView = createBannerView(adUnitID: adUnitIDs[0])
                bannerViews.append(bannerView)
                bannerView.load(GADRequest())
                return
            }
            
            let firstIDs = Array(adUnitIDs.dropLast())
            
            for (i, adUnitID) in firstIDs.enumerated() {
                let bannerView = createBannerView(adUnitID: adUnitID)
                bannerView.tag = i // Lưu vị trí để xác định thứ tự
                bannerViews.append(bannerView)
                bannerView.load(GADRequest())
            }
        }
        
        private func createBannerView(adUnitID: String) -> GADBannerView {
            if let bannerView = AdsManager.shared.cachedBannerAds[adUnitID] {
                bannerViewDidReceiveAd(bannerView)
                return bannerView
            } else {
                let bannerView = GADBannerView(adSize: GADAdSizeBanner)
                bannerView.adUnitID = adUnitID
                bannerView.delegate = self
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    bannerView.rootViewController = rootVC
                }
                
                return bannerView
            }
        }
      
        func bannerViewDidReceiveAdOther(_ bannerView: GADBannerView) {
            if let adUnitID = bannerView.adUnitID {
                AdsManager.shared.cachedBannerAds[adUnitID]  = bannerView
            }
            switch parent.loadType {
            
            case .fastest:
                if !hasDisplayedBanner {
                    displayBanner(bannerView)
                    cancelOthers(except: bannerView)
                }
                
            case .hfFastest:
                if !hasDisplayedBanner {
                    hasDisplayedBanner = true
                    displayBanner(bannerView)
                    cancelOthers(except: bannerView)
                }
                
            case .prioritySync:
        
                if !hasDisplayedBanner {
                    hasDisplayedBanner = true
                    displayBanner(bannerView)
                    cancelOthers(except: bannerView)
                }
                
            case .priorityAsync:
                
                bannerView.tag = bannerView.tag
                bannerView.accessibilityIdentifier = "SUCCESS"
            }
        }
        
        func bannerView(_ bannerView: GADBannerView,
                        didFailToReceiveAdWithError error: Error) {
            switch parent.loadType {
            case .fastest:
                
                break
                
            case .hfFastest:
               
                let firstIDsCount = parent.adUnitIDs.count - 1
                finishedCount += 1
                if finishedCount == firstIDsCount && !hasDisplayedBanner {
                  
                    if let lastID = parent.adUnitIDs.last {
                        let bannerView = createBannerView(adUnitID: lastID)
                        bannerViews.append(bannerView)
                        bannerView.load(GADRequest())
                    }
                }
                
            case .prioritySync:
                
                if !hasDisplayedBanner {
                    // Xem bannerView đang là index nào
                    let failIndex = bannerView.tag
                    loadBannerSequential(parent.adUnitIDs, index: failIndex + 1)
                }
                
            case .priorityAsync:
                // Đánh dấu banner này fail => increment finishedCount
                bannerView.accessibilityIdentifier = "FAIL"
            }
        }
        
      
        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        }
        
        private func cancelOthers(except chosenBanner: GADBannerView) {
            for bv in bannerViews {
                if bv != chosenBanner {
                    bv.delegate = nil
                    bv.removeFromSuperview()
                }
            }
        }
        
        private func displayBanner(_ bannerView: GADBannerView) {
            guard let container = containerView else { return }
            hasDisplayedBanner = true
            
            container.addSubview(bannerView)
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bannerView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                bannerView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
        }
        
        // MARK: - Handle finishing logic for type4
        override func responds(to aSelector: Selector!) -> Bool {
            return super.responds(to: aSelector)
        }
        
        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        }
        private func checkIfAllFirstIDsFinishedForType4() {
            let firstCount = parent.adUnitIDs.count - 1
            if finishedCount == firstCount {
               
                let successBanners = bannerViews.filter { $0.accessibilityIdentifier == "SUCCESS" }
                if !successBanners.isEmpty {
        
                    let sorted = successBanners.sorted { $0.tag < $1.tag }
                    if let firstBanner = sorted.first {
                        if !hasDisplayedBanner {
                            displayBanner(firstBanner)
                            cancelOthers(except: firstBanner)
                        }
                    }
                } else {
                    if let lastID = parent.adUnitIDs.last {
                        let bannerView = createBannerView(adUnitID: lastID)
                        bannerViews.append(bannerView)
                        bannerView.load(GADRequest())
                    }
                }
            }
        }
        
   
        func bannerViewDidReceiveAd_4(_ bannerView: GADBannerView) {
            finishedCount += 1
            checkIfAllFirstIDsFinishedForType4()
        }
        
        func bannerViewDidFail_4(_ bannerView: GADBannerView) {
            finishedCount += 1
            checkIfAllFirstIDsFinishedForType4()
        }
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView, forType4: Bool) {
            if forType4 {
                bannerViewDidReceiveAd_4(bannerView)
            } else {
                bannerViewDidReceiveAd(bannerView)
            }
        }
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            switch parent.loadType {
            case .priorityAsync:
                bannerView.accessibilityIdentifier = "SUCCESS"
                finishedCount += 1
                checkIfAllFirstIDsFinishedForType4()
            default:
                self.bannerViewDidReceiveAdOther(bannerView)
            }
        }
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error, forType4: Bool) {
            if forType4 {
                bannerView.accessibilityIdentifier = "FAIL"
                finishedCount += 1
                checkIfAllFirstIDsFinishedForType4()
            } else {
                self.bannerView(bannerView, didFailToReceiveAdWithError: error)
            }
        }
    }
}
