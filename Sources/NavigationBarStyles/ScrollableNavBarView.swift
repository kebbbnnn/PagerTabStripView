//
//  ScrollableNavBarView.swift
//  PagerTabStripView
//
//  Created by Cecilia Pirotto on 23/8/21.
//

import Foundation
import SwiftUI

internal struct ScrollableNavBarView: View {
    @Binding private var selection: Int
    @State private var switchAppeared: Bool = false
    
    @State private var putIndicatorAbove: Bool = false

    @EnvironmentObject private var dataStore: DataStore

    public init(selection: Binding<Int>) {
        self._selection = selection
    }

    @MainActor var body: some View {
        if let internalStyle = style as? BarButtonStyle {
            ScrollViewReader { value in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .center) {
                        VStack {
                            if self.putIndicatorAbove {
                                IndicatorScrollableBarView(selection: $selection)
                            }
                            /*HStack(spacing: internalStyle.tabItemSpacing) {
                                ForEach(0..<dataStore.itemsCount, id: \.self) { idx in
                                    NavBarItem(id: idx, selection: $selection)
                                }
                            }*/
                            Spacer()
                            
                            if !self.putIndicatorAbove {
                                IndicatorScrollableBarView(selection: $selection)
                            }
                        }
                        
                        HStack(spacing: internalStyle.tabItemSpacing) {
                            ForEach(0..<dataStore.itemsCount, id: \.self) { idx in
                                NavBarItem(id: idx, selection: $selection)
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(height: internalStyle.tabItemHeight)
                }
                .padding(internalStyle.padding)
                .onChange(of: switchAppeared) { _ in
                    // This is necessary because anchor: .center is not working correctly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        var remainingItemsWidth = (dataStore.getItemWidth(for: selection) ?? 0) / 2
                        let items = dataStore.items.filter { index, _ in
                            index > selection
                        }
                        remainingItemsWidth += items.map {dataStore.getItemWidth(for: $0.key) ?? 0}.reduce(0, +)
                        remainingItemsWidth += CGFloat(dataStore.items.count-1 - selection)*internalStyle.tabItemSpacing
                        let centerSel = remainingItemsWidth > settings.width/2
                        value.scrollTo(centerSel ? selection : dataStore.items.count-1, anchor: /*centerSel ? .center :*/ nil)
                    }
                }
                .onChange(of: selection) { newSelection in
                    withAnimation {
                        value.scrollTo(newSelection, anchor: .center)
                    }
                }
            }
            .onAppear {
                if case let .content(position) = internalStyle.placement, position == .bottom {
                    self.putIndicatorAbove = true
                }
                switchAppeared = !switchAppeared
            }
        }
    }

    @Environment(\.pagerStyle) var style: PagerStyle
    @EnvironmentObject private var settings: PagerSettings
}

internal struct IndicatorScrollableBarView: View {
    @EnvironmentObject private var dataStore: DataStore
    @Binding private var selection: Int
    @State private var position: Double = 0
    @State private var selectedItemWidth: Double = 0
    @State private var appeared: Bool = false

    public init(selection: Binding<Int>) {
        self._selection = selection
    }

    @MainActor var body: some View {
        if let internalStyle = style as? BarButtonStyle {
            internalStyle.indicatorView()
                .frame(height: internalStyle.indicatorViewHeight)
                .animation(.none, value: appeared)
                .frame(width: selectedItemWidth)
                .position(x: position)
                .onAppear {
                    appeared = true
                }
                .onChange(of: dataStore.widthUpdated) { updated in
                    if updated {
                        let items = dataStore.items.filter { index, _ in
                            index < selection
                        }
                        selectedItemWidth = dataStore.getItemWidth(for: selection) ?? 0
                        var newPosition = items.map({return dataStore.getItemWidth(for: $0.key) ?? 0}).reduce(0, +)
                        newPosition += (internalStyle.tabItemSpacing * CGFloat(selection)) + selectedItemWidth/2
                        position = newPosition
                    }
                }
                .onChange(of: settings.contentOffset) { newValue in
                    let offset = newValue + (settings.width * CGFloat(selection))
                    let percentage = offset / settings.width
                    let items = dataStore.items.filter { index, _ in
                        index < selection
                    }

                    let spaces = internalStyle.tabItemSpacing * CGFloat(selection-1)
                    let actualWidth = dataStore.getItemWidth(for: selection) ?? 0
                    var lastPosition = items.map({return dataStore.getItemWidth(for: $0.key) ?? 0}).reduce(0, +)
                    lastPosition += spaces + actualWidth/2
                    var nextPosition = items.map({return dataStore.getItemWidth(for: $0.key) ?? 0}).reduce(0, +)
                    if percentage == 0 {
                        selectedItemWidth = dataStore.getItemWidth(for: selection) ?? 0
                        var newPosition = items.map({return dataStore.getItemWidth(for: $0.key) ?? 0}).reduce(0, +)
                        newPosition += internalStyle.tabItemSpacing * CGFloat(selection) + selectedItemWidth/2
                        position = newPosition
                    } else {
                        if percentage < 0 {
                            nextPosition += actualWidth + internalStyle.tabItemSpacing * CGFloat(selection+1)
                            nextPosition += (dataStore.getItemWidth(for: selection + 1) ?? 0)/2
                        } else {
                            nextPosition += internalStyle.tabItemSpacing * CGFloat(selection-1)
                            nextPosition -= (dataStore.getItemWidth(for: selection - 1) ?? 0)/2
                        }
                        position = lastPosition + (nextPosition - lastPosition)*abs(percentage)

                        if let selectedWidth = dataStore.getItemWidth(for: selection),
                           let nextWidth = percentage > 0 ? dataStore.getItemWidth(for: selection-1) : dataStore.getItemWidth(for: selection+1),
                           abs(percentage)>0 {
                            selectedItemWidth = selectedWidth - (selectedWidth-nextWidth)*abs(percentage)
                        }
                    }

                }
                .onChange(of: selection) { newValue in
                    let items = dataStore.items.filter { index, _ in
                        index < newValue
                    }
                    
                    withAnimation(.easeInOut) {
                        selectedItemWidth = dataStore.getItemWidth(for: newValue) ?? 0
                        var newPosition = items.map({return dataStore.getItemWidth(for: $0.key) ?? 0}).reduce(0, +)
                        newPosition += (internalStyle.tabItemSpacing * CGFloat(newValue)) + selectedItemWidth/2
                        position = newPosition
                    }
                }
        }
    }

    @Environment(\.pagerStyle) var style: PagerStyle
    @EnvironmentObject private var settings: PagerSettings
}
