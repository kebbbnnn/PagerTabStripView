//
//  NavBarItem.swift
//  PagerTabStripView
//
//  Copyright © 2021 Xmartlabs SRL. All rights reserved.
//

import SwiftUI

public final class NavBarItemPressGestureState: ObservableObject {
    public enum PressGesture {
        case single(Int)
        case double(Int)
        case long(Int)
    }
    @MainActor
    @Published public private(set) var press: Optional<PressGesture> = .none
    
    @MainActor
    public init() {}
    
    @MainActor
    func set(_ press: PressGesture) {
        self.press = press
    }
}

struct NavBarItem: View, Identifiable {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var navBarItemPressGestureState: NavBarItemPressGestureState
    @Binding private var selection: Int
    internal var id: Int

    public init(id: Int, selection: Binding<Int>) {
        self._selection = selection
        self.id = id
    }

    @MainActor var body: some View {
        if id < dataStore.itemsCount {
            VStack {
                Button(action: {
                    let prevSelection = selection
                    selection = id
                    setNavBarItemPressGestureState(.single(prevSelection))
                }, label: {
                    dataStore.items[id]?.view
                })
                .buttonStyle(.plain)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
                    let prevSelection = selection
                    dataStore.items[id]?.tabViewDelegate?.setState(state: pressing ? .highlighted : (id == selection ? .selected : .normal))
                    if !pressing {
                        setNavBarItemPressGestureState(.long(prevSelection))
                    }
                } perform: {
                }
                .simultaneousGesture(TapGesture(count: 2).onEnded { _ in
                    setNavBarItemPressGestureState(.double(selection))
                })
            }.background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        dataStore.setItemWidth(for: id, value: geometry.size.width)
                        let widthUpdated = dataStore.items.filter({ $0.value.itemWidth ?? 0 > 0 }).count == dataStore.itemsCount
                        dataStore.widthUpdated = dataStore.itemsCount > 0 && widthUpdated
                    }
                }
            )
        }
    }
    
    func setNavBarItemPressGestureState(_ press: NavBarItemPressGestureState.PressGesture) {
        navBarItemPressGestureState.set(press)
    }
}
