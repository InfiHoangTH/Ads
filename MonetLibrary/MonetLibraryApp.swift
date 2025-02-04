//
//  MonetLibraryApp.swift
//  MonetLibrary
//
//  Created by Hoang on 22/1/25.
//

import SwiftUI
import GoogleMobileAds

@main
struct MonetLibraryApp: App {
    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    var body: some Scene {
        WindowGroup {
            HomeScreenView()
        }
    }
}
