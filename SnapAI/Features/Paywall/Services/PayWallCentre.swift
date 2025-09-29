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
            static let hasPayed   = "pay.hasPayed.v2"
            static let lockAtTS   = "pay.lockAtTS.v2"
        }
    
    @AppStorage("hasPayed") var hasPayed: Bool = false

    @AppStorage("paywallLockAtTS") private var lockAtTS: Double = 0

    @Published var isShowing: Bool = false
    private var forcedMode: PaywallMode? = nil
    private var oneShotTimer: Timer?
    
    var mode: PaywallMode {
        if let forcedMode { return forcedMode }
        if !hasPayed && lockAtTS == 0 { return .trialOffer }
        return .lockedAfterTrial
    }

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

    func startGraceMinuteAndClose() {
        guard !hasPayed else { isShowing = false; forcedMode = nil; return }
        forcedMode = nil
        scheduleLockdown(in: 60)
        isShowing = false
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

    func triggerLockdownIfNeeded() {
            guard !hasPayed, lockAtTS > 0 else { return }
            let now = Date().timeIntervalSince1970
            if now >= lockAtTS {
                          isShowing = true
                          forcedMode = .lockedAfterTrial
            }
        }

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
