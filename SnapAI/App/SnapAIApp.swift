//
//  SnapAIApp.swift
//  SnapAI
//
//  Created by Isa Melsov on 15/9/25.
//

import SwiftUI

@main
struct SnapAIApp: App {
    
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    
    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                NavigationView { /*PlanHostView()*/ MainScreen() }
            } else {
                OnboardingFlow {
                    hasOnboarded = true       // показать онбординг только один раз
                }
            }
        }
    }
}

//MARK: - PlanHostView.swift
struct PlanHostView: View {
    @State private var plan: PersonalPlan?
    private let repo = LocalRepository()
    var body: some View {
        Group {
            if let plan { PlanScreen(plan: plan) }
            else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Готовим ваш план…").foregroundColor(.secondary)
                    Button("Обновить") { load() }
                }.padding()
            }
        }
        .navigationTitle("Твой план")
        .onAppear(perform: load)
    }
    private func load() { plan = repo.fetchSavedPlan() }
}

