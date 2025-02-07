//
//  RemoteConfigManager.swift
//  MonetLibrary
//
//  Created by Hoang on 7/2/25.
//

import Foundation
import FirebaseRemoteConfig

class AdRemoteConfig {
    static let shared = AdRemoteConfig()
    private lazy var remoteConfig = RemoteConfig.remoteConfig()
    
    func bool(key: String) -> Bool {
        remoteConfig.configValue(forKey: key).boolValue
    }
}
