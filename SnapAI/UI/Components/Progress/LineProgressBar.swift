//
//  LineProgressBar.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

@MainActor
final class TimeManager: ObservableObject {
    @Published var displayedValue: CGFloat = 0
    @Published private(set) var isRunning = false

    private var timer: Timer?
    private var holdFullFrame = false

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            Task { @MainActor in self.tick(t) }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func tick(_ t: Timer) {
        guard isRunning else { t.invalidate(); return }
        let step: CGFloat = 0.01
        if holdFullFrame {
            holdFullFrame = false
            withAnimation(nil) { displayedValue = 0 }
            return
        }
        let next = displayedValue + step
        if next >= 1 {
            withAnimation(.linear(duration: 0.03)) { displayedValue = 1 }
            holdFullFrame = true
        } else {
            withAnimation(.linear(duration: 0.03)) { displayedValue = next }
        }
    }
}

@MainActor
struct LineProgressBar: View {
    @StateObject private var tm = TimeManager()

    private let segments = 6
    private let outerDiameter: CGFloat = 68
    private let ringWidth: CGFloat = 40
    private let barWidth: CGFloat = 3

    private let inactive = Color.white.opacity(0.5)
    private let active   = Color.white

    var body: some View {
        ZStack {
            ZStack {
                ForEach(0..<segments, id: \.self) { i in
                    let progress = Double(tm.displayedValue) * Double(segments)
                    let fill = max(0.0, min(1.0, progress - Double(i)))
                    let angle = Double(i) * 360.0 / Double(segments)
                    let centerRadius = outerDiameter/2 - ringWidth/2

                    let spoke =
                        RoundedRectangle(cornerRadius: barWidth/2)
                            .frame(width: barWidth, height: ringWidth - 32)
                            .offset(y: -centerRadius)
                            .rotationEffect(.degrees(angle))

                    spoke
                        .foregroundStyle(inactive)
                        .overlay(spoke.foregroundStyle(active).opacity(fill))
                }
            }
            .frame(width: outerDiameter, height: outerDiameter)
        }
        .onAppear { tm.start() }
        .onDisappear { tm.stop() }
    }
}

#Preview { LineProgressBar().background(Color.cyan) }



