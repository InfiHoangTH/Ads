//
//  NativeAdView.swift
//  MonetLibrary
//
//  Created by Hoang on 7/2/25.
//

import SwiftUI
import GoogleMobileAds
struct NativeAdView: View {
    let placement: AdsPlacementConfig
    @StateObject var nativeLoader: HFNativeLoader = HFNativeLoader()
    @State private var nativeAd: GADNativeAd? = nil
    
    var body: some View {
        ZStack {
            if let nativeAd  {
                NativeAdViewRepresentable(nativeAd: nativeAd)
            } else {
                EmptyView()
            }
        }.onFirstAppear {
            if case let AdsType.native(config) = placement.type {
                Task {
                    print("😍 Start load")
                    let ad = await nativeLoader.load(config: config)
                    print("😍 End load \(ad)")
                    nativeAd = ad
                }
            } else {
                fatalError("Ad config wrong type")
            }
        }
    }
}
//
//#Preview {
//    NativeAdView()
//}
