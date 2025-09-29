//
//  PayWallCentre.swift
//  SnapAI
//
//  Created by Isa Melsov on 27/9/25.
//

// PaywallCenter.swift
import SwiftUI

enum PaywallMode {
    case trialOffer          // стартовый paywall: с крестиком, "Start for free", с текстом trial
    case lockedAfterTrial    // «заблокировано»: без крестика, "Pay", без текста trial

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
            static let hasPayed   = "pay.hasPayed.v2"
            static let lockAtTS   = "pay.lockAtTS.v2"
        }
    
    // Флаг оплаты (твой "hasPayed")
    @AppStorage("hasPayed") var hasPayed: Bool = false

    // Когда должен «сработать» возврат paywall-а в locked-режиме
    @AppStorage("paywallLockAtTS") private var lockAtTS: Double = 0

    // Управление показом
    @Published var isShowing: Bool = false
    private var forcedMode: PaywallMode? = nil
    private var oneShotTimer: Timer?
    
    var mode: PaywallMode {
        if let forcedMode { return forcedMode }
        // не оплачен и grace не запускали → trial
        if !hasPayed && lockAtTS == 0 { return .trialOffer }
        // иначе locked
        return .lockedAfterTrial
    }

    // Открыть стартовый paywall (по кнопке Next)
    func presentInitial() {
            // если уже оплачен — вообще не показываем
            guard !hasPayed else { return }
            forcedMode = .trialOffer
            isShowing = true
        }
    
       // Открыть сразу locked (используем из Login)
       func presentLocked() {
           guard !hasPayed else { return }
           forcedMode = .lockedAfterTrial
           isShowing = true
       }

    // Нажали ✕ или "Start for free" → закрываем и ставим таймер на 1 мин
    func startGraceMinuteAndClose() {
        guard !hasPayed else { isShowing = false; forcedMode = nil; return }
        forcedMode = nil
        scheduleLockdown(in: 60)   // 60 сек
        isShowing = false          // уйти на экран под ним (Main / онбординг)
    }

    // Оплата (заглушка)
    func payStub() {
        hasPayed = true
        isShowing = false
        lockAtTS = 0
        oneShotTimer?.invalidate()
        oneShotTimer = nil
        forcedMode = nil
    }

    // Проверка при возврате в актив (или по таймеру)
    func triggerLockdownIfNeeded() {
            guard !hasPayed, lockAtTS > 0 else { return }
            let now = Date().timeIntervalSince1970
            if now >= lockAtTS {
                          isShowing = true
                          forcedMode = .lockedAfterTrial
            }
        }

    // Звать из scenePhase == .active
    func onBecameActive() {
            triggerLockdownIfNeeded()
            if !hasPayed, lockAtTS > 0 {
                let left = lockAtTS - Date().timeIntervalSince1970
                if left > 0 { scheduleLockdown(in: left) }
            }
        }

    private func scheduleLockdown(in seconds: TimeInterval) {
            lockAtTS = Date().timeIntervalSince1970 + seconds
            oneShotTimer?.invalidate()
            guard seconds > 0.01 else { triggerLockdownIfNeeded(); return }
            let t = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.triggerLockdownIfNeeded() }
            }
            oneShotTimer = t
            RunLoop.main.add(t, forMode: .common)
        }
}
