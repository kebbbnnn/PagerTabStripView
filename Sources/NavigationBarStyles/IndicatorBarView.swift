//
//  IndicatorBarView.swift
//  PagerTabStripView
//
//  Copyright © 2021 Xmartlabs SRL. All rights reserved.
//

import Foundation
import SwiftUI

internal struct IndicatorBarView<Indicator, BG>: View where Indicator: View, BG: View {
    @EnvironmentObject private var dataStore: DataStore
    @ViewBuilder var indicator: () -> Indicator
    @ViewBuilder var background: () -> BG

    var body: some View {
        if let internalStyle = style as? PagerWithIndicatorStyle {
            ZStack {
                background()
                let totalItemWidth = (settings.width - (internalStyle.tabItemSpacing * CGFloat(dataStore.itemsCount - 1)))
                let navBarItemWidth = totalItemWidth / CGFloat(dataStore.itemsCount)
                if let navBarItemWidth, navBarItemWidth > 0, navBarItemWidth <= settings.width {
                    let x = -settings.contentOffset / CGFloat(dataStore.itemsCount) + navBarItemWidth / 2
                    indicator()
                        .animation(.default)
                        .frame(width: navBarItemWidth)
                        .position(x: x, y: internalStyle.indicatorViewHeight / 2)
                }
            }
            .frame(height: internalStyle.indicatorViewHeight)
        }
    }

    @Environment(\.pagerStyle) var style: PagerStyle
    @EnvironmentObject private var settings: PagerSettings
}
