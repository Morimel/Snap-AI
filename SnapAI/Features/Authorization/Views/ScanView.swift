import SwiftUI

struct FocusSquare: View {
    var size: CGFloat = 260
    var lineWidth: CGFloat = 8
    var color: Color = .white

    var innerInset: CGFloat = 14
    var innerCornerRadius: CGFloat = 22

    var sweepPeriod: Double = 1.6
    var triggerInterval: Double = 3.0
    var sweepThickness: CGFloat = 0.45

    @State private var sweepPhase: CGFloat = -1.2
    @State private var animTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            MyIcon()
                .fill(color)
                .frame(width: size, height: size)
                .allowsHitTesting(false)

            sweep
                .frame(
                    width: size - innerInset * 2,
                    height: size - innerInset * 2
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous)
                )
                .allowsHitTesting(false)
        }
        .onAppear { startLoop() }
        .onDisappear {
            animTask?.cancel()
            animTask = nil
            sweepPhase = -1.2
        }
        .accessibilityHidden(true)
    }

    private func startLoop() {
        animTask?.cancel()
        animTask = Task {
            while !Task.isCancelled {
                await MainActor.run { sweepPhase = -1.2 }

                await MainActor.run {
                    withAnimation(.linear(duration: sweepPeriod)) {
                        sweepPhase = 1.2
                    }
                }

                try? await Task.sleep(nanoseconds: UInt64(sweepPeriod * 1_000_000_000))

                let rest = max(0, triggerInterval - sweepPeriod)
                try? await Task.sleep(nanoseconds: UInt64(rest * 1_000_000_000))
            }
        }
    }

    private var sweep: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bandH = h * sweepThickness
            let travel = h + bandH

            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .white.opacity(0.0),  location: 0.20),
                            .init(color: .white.opacity(0.75), location: 0.50),
                            .init(color: .white.opacity(0.0),  location: 0.80),
                        ]),
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .blendMode(.screen)
                .frame(width: w, height: bandH)
                .offset(y: sweepPhase * travel)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FocusSquare(size: 260, lineWidth: 8, innerInset: 14, innerCornerRadius: 24,
                    sweepPeriod: 1.2, triggerInterval: 5.0)
    }
}
