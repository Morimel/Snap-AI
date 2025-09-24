//
//  WheelPicker.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - Time Picker
struct WheelPicker<ItemView: View>: View {
    @Binding var selectedIndex: Int
    let count: Int
    let row: (Int, Bool) -> ItemView
    
    var columnWidth: CGFloat = 140
    var itemHeight: CGFloat = 58
    var visibleRows: Int = 5
    var pillHeight: CGFloat = 36
    var pillHorizontalInset: CGFloat = 16
    var tiltDegrees: Double = 40
    
    @State private var containerMidY: CGFloat = .zero
    @State private var isDragging = false
    @State private var pendingIndex: Int? = nil     // 👈 сюда складываем ближайший индекс во время скролла
    
    private var rowsAbove: Int { (visibleRows - 1) / 2 }
    private var topBottomInset: CGFloat { CGFloat(rowsAbove) * itemHeight }
    
    private let wheelSpace = "wheelSpace" // 👈
    
    var body: some View {
        GeometryReader { _ in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<count, id: \.self) { i in
                            let isSel = i == selectedIndex
                            let diff = Double(i - selectedIndex)
                            
                            row(i, isSel)
                                .frame(height: itemHeight)
                                .rotation3DEffect(
                                    .degrees((-tiltDegrees / Double(max(rowsAbove, 1))) * diff),
                                    axis: (x: 1, y: 0, z: 0),
                                    perspective: 0.6
                                )
                                .opacity(isSel ? 1.0 : 0.65)
                                .background(
                                    GeometryReader { rowGeo in
                                        Color.clear.preference(
                                            key: RowDistanceKey.self,
                                            value: [i: abs(rowGeo.frame(in: .named(wheelSpace)).midY - containerMidY)]
                                        )
                                    }
                                )
                                .id(i)
                        }
                    }
                    .padding(.vertical, topBottomInset)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { containerMidY = geo.frame(in: .named(wheelSpace)).midY }
                            .onChange(of: geo.frame(in: .named(wheelSpace)).midY) { containerMidY = $0 }
                    }
                )
                .coordinateSpace(name: wheelSpace)
                .gesture(
                    DragGesture()
                        .onChanged { _ in
                            if !isDragging { isDragging = true }
                        }
                        .onEnded { _ in
                            isDragging = false
                            let target = pendingIndex ?? selectedIndex
                            pendingIndex = nil
                            if target != selectedIndex { selectedIndex = target }
                            
                            // ✅ haptic feedback
                            let gen = UIImpactFeedbackGenerator(style: .light)
                            gen.impactOccurred()
                            
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(target, anchor: .center)
                            }
                        }
                )
                .onAppear {
                    proxy.scrollTo(selectedIndex, anchor: .center)
                }
                .onChange(of: selectedIndex) { new in
                    guard !isDragging else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(new, anchor: .center)
                    }
                }
                .onPreferenceChange(RowDistanceKey.self) { distances in
                    guard !distances.isEmpty else { return }
                    if let nearest = distances.min(by: { $0.value < $1.value })?.key {
                        if isDragging {
                            // во время скролла просто запоминаем — не дёргаем прокрутку
                            pendingIndex = nearest
                        } else if nearest != selectedIndex {
                            selectedIndex = nearest
                        }
                    }
                }
            }
        }
        .frame(width: columnWidth, height: itemHeight * CGFloat(visibleRows))
        .background(alignment: .center) {
            Capsule()
                .fill(AppColors.primary)
                .frame(height: pillHeight)
                .padding(.horizontal, pillHorizontalInset)
                .allowsHitTesting(false)
        }
    }
}

private struct RowDistanceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
