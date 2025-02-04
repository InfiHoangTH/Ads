//
//  UserDefaultManager.swift
//  MonetLibrary
//
//  Created by Hoang on 4/2/25.
//

import Foundation

public class UserDefaultManager: ObservableObject {
    public static let shared = UserDefaultManager()
    let bundleId = Bundle.main.bundleIdentifier
    private let userDefault: UserDefaults!
    
    init() {
        userDefault = UserDefaults(suiteName: bundleId)
    }
    
    public enum UserDefaultKeys: String {
        case isPurchased
    }
}

extension UserDefaultManager {
    public func getValue<T>(for key: String) -> T? {
        userDefault.value(forKey: key) as? T
    }
    
    public func setValue<T>(_ value: T?, for key: String) {
        userDefault.setValue(value, forKey: key)
    }
    
    public func setValue<T>(_ value: T?, for key: UserDefaultKeys) {
        userDefault.setValue(value, forKey: key.rawValue)
    }
    
    private func getBool(for key:UserDefaultKeys) -> Bool? { getValue(for: key.rawValue)}
    
    private func getInt(for key:UserDefaultKeys) -> Int?  { getValue(for: key.rawValue)}
    
    private func getString(for key: UserDefaultKeys) -> String? {getValue(for: key.rawValue)}
    
    
    
}

extension UserDefaultManager {
    public var isPurchased: Bool {
        get {
            getBool(for:.isPurchased ) ?? false
        }
        set {
            setValue(newValue, for: .isPurchased)
        }
    }
}

public let defaultConfig = UserDefaultManager.shared
