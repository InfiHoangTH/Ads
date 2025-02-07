//
//  HomeScreenView.swift
//  MonetLibrary
//
//  Created by Hoang on 22/1/25.
//

import SwiftUI

struct HomeScreenView: View {
    @StateObject private var adManager = InterstitialAdManager()
    var body: some View {
        ZStack {
            VStack {
                Button(action: {
                    AdsManager.shared.show(placementConfig:  AdsPlacement.home.getConfig()) {
                        print("😍 Show inter ne")
                    }
//                    showInterstitialAd()
//                    AdsManager.shared.show(placementConfig: AdsPlacement.reward.getConfig(), action: {})
                }, label: {Text("test")})
                BannerAdView(config: AdsManager.shared.getBannerConfig(placementConfig: AdsPlacement.banner.getConfig())!)
                NativeAdView(placement: AdsPlacement.native.getConfig())
                if AdsManager.shared.interstitialManager.isLoading {
                    Text("Loading")
                } else {
                    Text("Loaded")
                }
            }
        }.onAppear(perform: {
            
        }).background {
          
        }
    }
    
    func showInterstitialAd() {
        if let rootVC = getRootViewController() {
              adManager.showAd(from: rootVC)
          }
      }
}

#Preview {
    HomeScreenView()
}
