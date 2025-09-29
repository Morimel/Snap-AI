//
//  WheelPicker.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI
import Combine

struct CustomWheelPicker: View {
    // MARK: - External API
    let items: [String]
    @Binding var selectedIndex: Int
    var itemHeight: CGFloat = 50
    var visibleItems: Int = 5
    var columnWidth: CGFloat = 92
    var onSelectionChange: ((String) -> Void)? = nil

    // MARK: - Internal state
    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    // Haptic
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Init (удобные метки)
    init(items: [String],
         selectedIndex: Binding<Int>,
         columnWidth: CGFloat = 92,
         itemHeight: CGFloat = 50,
         visibleItems: Int = 5,
         onSelectionChange: ((String) -> Void)? = nil) {
        self.items = items
        self._selectedIndex = selectedIndex
        self.columnWidth = columnWidth
        self.itemHeight = itemHeight
        self.visibleItems = visibleItems
        self.onSelectionChange = onSelectionChange
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            VStack {
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(items.indices, id: \.self) { index in
                                let isSelected = selectedIndex == index

                                Text(items[index])
                                    .font(.title3.weight(isSelected ? .bold : .semibold))
                                    .foregroundStyle(isSelected ? Color.white : AppColors.primary)
                                    .frame(height: itemHeight)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? AppColors.primary : .clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                                    .scaleEffect(x: 1.0, y: isSelected ? 1.10 : 1.0, anchor: .center)
                                    .rotation3DEffect(
                                        .degrees(isSelected ? 0 : 8),
                                        axis: (x: 1, y: 0, z: 0)
                                    )
                                    .accessibilityLabel(items[index])
                            }
                        }
                        .padding(.vertical, (geometry.size.height - itemHeight) / 2) // центрируем окно
                        .offset(y: offset + dragOffset)
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation.height
                                }
                                .onEnded(onDragEnded)
                        )
                        .animation(.easeInOut, value: offset)
                    }
                }
                .frame(width: columnWidth, height: CGFloat(visibleItems) * itemHeight)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(radius: 10)
                .padding(.all, 4)
            }
        }
        // начальное выравнивание по внешнему индексу
        .onAppear {
            offset = -CGFloat(selectedIndex) * itemHeight
        }
        // если индекс поменялся снаружи — скроллимся к нему
        .onChange(of: selectedIndex) { new in
            withAnimation(.easeInOut) {
                offset = -CGFloat(new) * itemHeight
            }
        }
    }

    // MARK: - Methods
    private func onDragEnded(drag: DragGesture.Value) {
        var newOffset = offset + drag.translation.height

        let rawIndex = round(-newOffset / itemHeight)
        let boundedIndex = min(max(rawIndex, 0), CGFloat(items.count - 1))
        newOffset = -boundedIndex * itemHeight

        offset = newOffset
        let newSelectedIndex = Int(boundedIndex)

        if selectedIndex != newSelectedIndex {
            selectedIndex = newSelectedIndex
            onSelectionChange?(items[newSelectedIndex])
            haptic.impactOccurred()
        }
    }
}



#Preview("Minutes 00–59") {
    PreviewMinutes()
}

private struct PreviewMinutes: View {
    @State private var sel = 15
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CustomWheelPicker(
                items: Array(0..<60).map { String(format: "%02d", $0) },
                selectedIndex: $sel
            )
            .preferredColorScheme(.dark)
        }
    }
}
