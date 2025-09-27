//
//  SettingsView.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Settings Screen
struct SettingsView: View {
    @ObservedObject var vm: OnboardingViewModel

    // Данные для примера; подмени своими
    @State private var gender = "Male"
    @State private var age = "27 years old"
    @State private var height = "5'9\""
    @State private var weight = "150 lbs"
    @State private var goal = "135 lbs"
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Карточка с ключ-значение
                SectionCard {
                    KeyValueRow(key: "Gender", value: gender)
                    KeyValueRow(key: "Age", value: age)
                    KeyValueRow(key: "Height", value: height)
                    KeyValueRow(key: "Weight", value: weight)
                    KeyValueRow(key: "Goal", value: goal)
                }
                
                // Персонализация
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Personalization")
                    SectionCard {
                        NavigationLink {
                            PersonalDataView(
                                vm: vm,
                                gender: $gender,
                                age: $age,
                                height: $height,
                                weight: $weight
                            )
                            .navigationTitle("Personal data")
                            .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            HStack {
                                Text("Personal information")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppColors.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.primary)
                            }
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                        }
                        ChevronRow(title: "Change goals") {
                            // TODO: открыть экран смены целей
                        }
                        NavigationLink {
                            ChangeTargetView()
                        } label: {
                            HStack {
                                Text("Change targets")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppColors.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.primary)
                            }
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                // Support
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Support service")
                    SectionCard {
                        ChevronRow(title: "Support service") {
                            // TODO: открыть чат/почту
                        }
                        ChevronRow(title: "Terms") { }
                        ChevronRow(title: "Privacy") { }
                    }
                }
                
                Text("App version: 1.0.0")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.vertical, 16)
        }
        .background(AppColors.background.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    AppImages.ButtonIcons.arrowRight
                        .resizable()
                        .scaledToFill()
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(180))
                        .padding()
                }
                
                Text("Settings")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 24, weight: .semibold))
                
            }
        }
    }
}

#Preview {
    SettingsView_Preview()
}

private struct SettingsView_Preview: View {
    @StateObject private var vm = OnboardingViewModel(
        repository: LocalRepository(),
        onFinished: {}
    )

    var body: some View {
        NavigationStack {
            SettingsView(vm: vm)
        }
    }
}
