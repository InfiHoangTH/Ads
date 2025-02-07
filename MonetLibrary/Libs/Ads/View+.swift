//
//  View+.swift
//  MonetLibrary
//
//  Created by Hoang on 7/2/25.
//

import Foundation
import SwiftUI

extension View {
    func onCustomAppear(first: @escaping ()->Void, seconds: @escaping ()->Void) -> some View {
        return self.modifier(CustomAppearModifier(firstPerform: first, secondsPerform: seconds))
    }
    
    func onFirstAppear(perform: @escaping ()->Void) -> some View {
        return self.modifier(FirstAppearModifier(perform: perform))
    }
}

private struct FirstAppearModifier: ViewModifier {
    let perform: () -> Void
    @State private var firstAppear: Bool = true
    func body(content: Content) -> some View {
        content
            .onAppear(perform: {
                if firstAppear {
                    firstAppear = false
                    self.perform()
                }
            })
    }
}
private struct CustomAppearModifier: ViewModifier {
    let firstPerform: () -> Void
    let secondsPerform: () -> Void
    @State private var firstAppear: Bool = true
    
    func body(content: Content) -> some View {
        content
            .onAppear(perform: {
                if firstAppear {
                    firstAppear = false
                    self.firstPerform()
                } else {
                    self.secondsPerform()
                }
            })
    }
}

