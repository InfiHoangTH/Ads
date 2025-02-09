//
//  HomeScreenView.swift
//  MonetLibrary
//
//  Created by Hoang on 22/1/25.
//

import SwiftUI

struct HomeScreenView: View {
    @StateObject private var adManager = InterstitialAdManager()
    @ObservedObject
    var ads = AdsManager.shared

    var body: some View {
        ZStack {
            VStack {
                Button(action: {
                    AdsManager.shared.show(placementConfig:  AdsPlacement.home.getConfig()) {
                        print("😍 Dismiss interstitial")
                    }

                }, label: {Text("Show Interstitial")})
                Button {
                    AdsManager.shared.show(placementConfig: AdsPlacement.reward.getConfig()) {
                        print("😍 Earn reward")
                    }
                } label: {
                    Text("Show Reward Ad")
                }

                BannerAdView(config: AdsManager.shared.getBannerConfig(placementConfig: AdsPlacement.banner.getConfig())!)
                NativeAdView(placement: AdsPlacement.native.getConfig())
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
