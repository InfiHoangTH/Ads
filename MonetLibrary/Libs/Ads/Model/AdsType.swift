//
//  AdsType.swift
//  MonetLibrary
//
//  Created by Hoang on 22/1/25.
//

import Foundation

enum AdsType {
    case banner(BannerConfig)
    case native(NativeConfig)
    case interstitial(InterstitialConfig)
    case reward(RewardConfig)
}
