//
//  PayWallCentre.swift
//  SnapAI
//
//  Created by Isa Melsov on 27/9/25.
//

// PaywallCenter.swift
import SwiftUI

enum PaywallMode {
    case trialOffer          
    case lockedAfterTrial

    var ctaTitle: String {
        switch self {
        case .trialOffer:       return "Start for free"
        case .lockedAfterTrial: return "Pay"
        }
    }
    var showsClose: Bool {
        self == .trialOffer
    }
    var showsTrialTerms: Bool {
        self == .trialOffer
    }
}

@MainActor
final class PaywallCenter: ObservableObject {

    private enum Keys {
        static let hasPayed        = "pay.hasPayed.v3"          // флаг «активно оплачено»
        static let trialStartTS    = "pay.trialStartTS.v1"      // старт триала (unix)
        static let subExpiresAtTS  = "pay.subExpiresAtTS.v1"    // окончание подписки (unix)
        static let nextWakeTS      = "pay.nextWakeTS.v1"        // когда проснуться таймеру
        // ⚙️ DEBUG: 1 «день» = N секунд (для теста). В релизе держите 86400.
        static let secondsPerDay   = "pay.debug.secondsPerDay"  // по умолчанию 86400
    }

    // Хранилище
    @AppStorage(Keys.hasPayed)       var hasPayed: Bool = false
    @AppStorage(Keys.trialStartTS)   private var trialStartTS: Double = 0
    @AppStorage(Keys.subExpiresAtTS) private var subExpiresAtTS: Double = 0
    @AppStorage(Keys.nextWakeTS)     private var nextWakeTS: Double = 0
    @AppStorage(Keys.secondsPerDay)  private var secondsPerDay: Double = 86_400 // 1 сутки

    // UI-состояние
    @Published var isShowing: Bool = false
    private var forcedMode: PaywallMode? = nil
    private var oneShotTimer: Timer?

    // Константы длительностей (масштабируемые для теста)
    private var now: TimeInterval { Date().timeIntervalSince1970 }
    private var day: TimeInterval { max(1, secondsPerDay) }
    private var trialLength: TimeInterval { 7 * day }              // 7 дней
    private var monthLength: TimeInterval { 30 * day }             // условный «месяц»
    private var yearLength: TimeInterval { 365 * day }

    // Текущий режим экрана
    var mode: PaywallMode {
        if let forcedMode { return forcedMode }
        // если не оплачено и триал не начат или активен — предлагаем триал
        if !hasPayed && (trialStartTS == 0 || now < trialStartTS + trialLength) {
            return .trialOffer
        }
        // иначе — экран «Pay»
        return .lockedAfterTrial
    }

    // MARK: Публичные действия

    func presentInitial() {
        guard !hasPayed else { return }
        forcedMode = .trialOffer
        isShowing = true
    }

    func presentLocked() {
        guard !hasPayed else { return }
        forcedMode = .lockedAfterTrial
        isShowing = true
    }

    /// Запускаем 7-дневный триал и закрываем paywall.
    func startTrialAndClose() {
        guard !hasPayed else { isShowing = false; forcedMode = nil; return }
        if trialStartTS == 0 { trialStartTS = now }
        scheduleWake(at: trialStartTS + trialLength)
        isShowing = false
        forcedMode = nil
    }

    /// «Оплата» (заглушка): активируем подписку и закрываем paywall.
    func payStub(for product: Product) {
        let expires = now + (product == .monthly ? monthLength : yearLength)
        subExpiresAtTS = expires
        hasPayed = true
        isShowing = false
        forcedMode = nil
        scheduleWake(at: expires)               // проснёмся в момент окончания
    }

    /// Вызывать при возврате приложения на экран (scenePhase == .active).
    func onBecameActive() {
        evaluateState()
    }

    // MARK: Внутреннее

    private func scheduleWake(at ts: TimeInterval) {
        nextWakeTS = ts
        oneShotTimer?.invalidate()
        let delay = ts - now
        guard delay > 0.01 else { evaluateState(); return }
        let t = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.evaluateState() }
        }
        oneShotTimer = t
        RunLoop.main.add(t, forMode: .common)
    }

    private func evaluateState() {
        let n = now

        // 1) Подписка закончилась → сбрасываем hasPayed и открываем paywall (экран Pay)
        if hasPayed, subExpiresAtTS > 0, n >= subExpiresAtTS {
            hasPayed = false
            isShowing = true
            forcedMode = .lockedAfterTrial
            return
        }

        // 2) Триал закончился и не оплачено → открываем paywall (экран Pay)
        if !hasPayed, trialStartTS > 0, n >= trialStartTS + trialLength {
            isShowing = true
            forcedMode = .lockedAfterTrial
            return
        }

        // 3) Переназначим таймер на ближайшее «важное» время
        if hasPayed, subExpiresAtTS > 0 {
            scheduleWake(at: subExpiresAtTS)
        } else if trialStartTS > 0 {
            scheduleWake(at: trialStartTS + trialLength)
        }
    }

    // ===== DEBUG Helpers =====
    #if DEBUG
    /// Ускорить время для теста: 1 «день» = seconds (например, 10 секунд)
    func debug_setSecondsPerDay(_ seconds: Double) {
        secondsPerDay = max(1, seconds)
        evaluateState()
    }
    #endif
}
