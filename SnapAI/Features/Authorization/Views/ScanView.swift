import SwiftUI

/// Рамка из MyIcon + вертикальный light sweep, который появляется раз в N секунд
struct FocusSquare: View {
    var size: CGFloat = 260
    var lineWidth: CGFloat = 8
    var color: Color = .white

    // область, куда ездит блик (немного меньше рамки)
    var innerInset: CGFloat = 14
    var innerCornerRadius: CGFloat = 22

    /// длительность одного прохода блика
    var sweepPeriod: Double = 1.6
    /// период между стартами проходов (раз в сколько секунд «появляется» анимация)
    var triggerInterval: Double = 3.0
    /// относительная толщина световой полосы
    var sweepThickness: CGFloat = 0.45

    @State private var sweepPhase: CGFloat = -1.2
    @State private var animTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            // Рамка уголками
            MyIcon()
                .fill(color)
                .frame(width: size, height: size)
                .allowsHitTesting(false)

            // Блик внутри
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
                // сбросим полосу наверх, вне экрана
                await MainActor.run { sweepPhase = -1.2 }

                // запустим проезд
                await MainActor.run {
                    withAnimation(.linear(duration: sweepPeriod)) {
                        sweepPhase = 1.2
                    }
                }

                // подождём, пока проезд завершится
                try? await Task.sleep(nanoseconds: UInt64(sweepPeriod * 1_000_000_000))

                // пауза до следующего запуска (если период меньше sweepPeriod, паузы не будет)
                let rest = max(0, triggerInterval - sweepPeriod)
                try? await Task.sleep(nanoseconds: UInt64(rest * 1_000_000_000))
            }
        }
    }

    // Вертикальная «полоса света», проезжающая сверху вниз
    private var sweep: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bandH = h * sweepThickness
            let travel = h + bandH // чтобы полоса полностью входила/выходила

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
