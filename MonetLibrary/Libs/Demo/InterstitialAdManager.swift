//
//  InterstitialAdManager.swift
//  MonetLibrary
//
//  Created by Hoang on 4/2/25.
//
import GoogleMobileAds
import UIKit

class InterstitialAdManager: NSObject, GADFullScreenContentDelegate, ObservableObject {
    private var interstitial: GADInterstitialAd?

    override init() {
        super.init()
        loadAd()
    }

    /// Loads a new interstitial ad
    func loadAd() {
        let request = GADRequest()
        GADInterstitialAd.load(
            withAdUnitID: "ca-app-pub-3940256099942544/4411468910", // Test Ad ID
            request: request
        ) { ad, error in
            if let error = error {
                print("Failed to load ad: \(error.localizedDescription)")
                return
            }
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
        }
    }

    /// Show the ad if it's ready
    func showAd(from rootViewController: UIViewController) {
        if let ad = interstitial {
            ad.present(fromRootViewController: rootViewController)
        } else {
            print("Ad is not ready")
            loadAd() // Reload if needed
        }
    }

    /// Called when ad is dismissed, reload new ad
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad dismissed")
        loadAd()
    }
}
