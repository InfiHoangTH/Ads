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
    case reward
    case banner
    func getConfig() -> AdsPlacementConfig {
        switch self {
        case .home:
            return AdsPlacementConfig(type: .interstitial(InterstitialConfig(adUnits:["", AdUnit.interstitialHome.rawValue, AdUnit.interstitialHome.rawValue],loadType: .prioritySync)), activeConfigKey: "enable_home")
        case .reward:
            return AdsPlacementConfig(type: .reward(RewardConfig(id: "ca-app-pub-3940256099942544/1712485313")), activeConfigKey: "enable_reward")
            
        case .banner:
            return AdsPlacementConfig(type: .banner(BannerConfig(ids: ["ca-app-pub-3940256099942544/2934735716", "ca-app-pub-3940256099942544/2934735716", "ca-app-pub-3940256099942544/2934735716"], loadType: .priorityAsync)), activeConfigKey: "--")
    

        default:
            fatalError("Ads not config")
        }
    }
}


enum AdUnit: String {
#if DEBUG
    case interstitialHome = "ca-app-pub-3940256099942544/4411468910"
#else
    case interstitialHome = ""
#endif
}



