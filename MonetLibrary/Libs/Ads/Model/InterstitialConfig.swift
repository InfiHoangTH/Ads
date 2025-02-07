//
//  InterstitialConfig.swift
//  MonetLibrary
//
//  Created by Hoang on 22/1/25.
//

import Foundation
struct InterstitialConfig {
    let id: String = UUID().uuidString
    let adUnits: [String]
    var loadType: LoadType = .fastest
}
