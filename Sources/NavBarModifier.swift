//
//  NavBarModifier.swift
//  PagerTabStripView
//
//  Copyright © 2021 Xmartlabs SRL. All rights reserved.
//

import SwiftUI

struct NavBarModifier: ViewModifier {
    @Binding private var selection: Int

    public init(selection: Binding<Int>) {
        self._selection = selection
    }

    @MainActor func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch style.placement {
            case .content(let position):
                switch position {
                case .top:
                    NavBarWrapperView(selection: $selection)
                    content
                case .bottom:
                    content
                        .overlay(ContentTapAbsorptionBlockerOverlay()) /// A hack to prevent content absobing the tap when top most area of nav bar was tapped.
                    NavBarWrapperView(selection: $selection)
                }
            case .toolbar:
                content.toolbar(content: {
                    ToolbarItem(placement: .principal) {
                        NavBarWrapperView(selection: $selection)
                    }
                })
            }
        }
    }
    
    @ViewBuilder
    func ContentTapAbsorptionBlockerOverlay() -> some View {
        VStack {
            Spacer()
            
            Color.clear
                .frame(height: 8)
                .contentShape(Rectangle())
        }
        .frame(maxHeight: .infinity)
    }
    
    @Environment(\.pagerStyle) var style: PagerStyle
}

private struct NavBarWrapperView: View {
    @Binding var selection: Int

    @MainActor var body: some View {
        switch style {
        case let barStyle as BarStyle:
            IndicatorBarView(indicator: barStyle.indicatorView, background: barStyle.barBackgroundView)
        case is SegmentedControlStyle:
            SegmentedNavBarView(selection: $selection)
        case let indicatorStyle as BarButtonStyle:
            if indicatorStyle.scrollable {
                ScrollableNavBarView(selection: $selection)
                    .background(indicatorStyle.barBackgroundView())
            } else {
                FixedSizeNavBarView(selection: $selection) { indicatorStyle.barBackgroundView() }
                IndicatorBarView(indicator: indicatorStyle.indicatorView, background: { EmptyView() })
            }
        default:
            SegmentedNavBarView(selection: $selection)
        }
    }

    @Environment(\.pagerStyle) var style: PagerStyle
}
