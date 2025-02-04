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
            Button(action: {
                showInterstitialAd()
            }, label: {Text("test")})
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
