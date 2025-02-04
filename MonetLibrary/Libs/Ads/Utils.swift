//
//  Utils.swift
//  MonetLibrary
//
//  Created by Hoang on 4/2/25.
//

import Foundation
import UIKit

func getCurrentTime()->Double {
    return Date().timeIntervalSince1970
}
func getRootViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes
            .first as? UIWindowScene,
          let window = windowScene.windows.first else {
        return nil
    }
    return window.rootViewController
}
