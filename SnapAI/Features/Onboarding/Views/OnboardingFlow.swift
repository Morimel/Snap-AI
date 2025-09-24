//
//  OnboardingFlow.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct OnboardingFlow: View {
    @StateObject private var vm: OnboardingViewModel
    
    init(onFinished: @escaping () -> Void) {
        // подставьте реальный baseURL и токен (из логина)
        //        let repo = APIRepository(baseURL: URL(string: "https://api.yourserver.com")!,
        //                                 authToken: "<JWT>")
        let repo = LocalRepository()  // ⬅️ сюда
        _vm = StateObject(wrappedValue: OnboardingViewModel(repository: repo,
                                                            onFinished: onFinished))
    }
    
    var body: some View {
        NavigationStack { StartStep(vm: vm) }
    }
}
