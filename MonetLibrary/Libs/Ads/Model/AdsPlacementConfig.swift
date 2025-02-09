//
//  AdsPlacementConfig.swift
//  MonetLibrary
//
//  Created by Hoang on 23/1/25.
//

import Foundation

struct AdsPlacementConfig {
    let type: AdsType
    let screenName: String = "Unknown"
    let activeConfigKey: String
    let needPreload: Bool = false
}
