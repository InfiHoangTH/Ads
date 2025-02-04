//
//  AdsPosition.swift
//  MonetLibrary
//
//  Created by Hoang on 23/1/25.
//

import Foundation

enum AdsPlacement {
    case splash
    case home
    
    func getConfig() -> AdsPlacementConfig {
        switch self {
        case .home:
            return AdsPlacementConfig(type: .interstitial(InterstitialConfig(adUnits:[AdUnit.interstitialHome.rawValue])), activeConfigKey: "enable_home")
    

        default:
            fatalError("Ads not config")
        }
    }
}


enum AdUnit: String {
#if DEBUG
    case interstitialHome = ""
#else
    case interstitialHome = ""
#endif
}



