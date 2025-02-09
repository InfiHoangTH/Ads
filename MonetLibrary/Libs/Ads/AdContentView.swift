//
//  AdContentView.swift
//  MonetLibrary
//
//  Created by Thang Huy Hoang on 9/2/25.
//

import SwiftUI

struct AdContentView<Content: View>: View {
    @ObservedObject var adManger: AdsManager = AdsManager.shared
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            content
            if adManger.isLoadingAd {
                loadingView
            } else {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    var loadingView: some View{
        ZStack(alignment: .center) {
            Color.white.ignoresSafeArea()
            VStack {
                Spacer()
                ProgressView()
                Text("Loading Ad...")
                Spacer()
            }
        }
    }
    
}

