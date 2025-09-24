//
//  LabeledPillRow.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Reusable row (как у тебя)
struct LabeledPillRow: View {
    let label: String
    let value: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.title3.weight(.semibold))
                .foregroundColor(AppColors.primary)
                .padding(.horizontal, 16)

            Button(action: action) {
                HStack {
                    Text(value)
                        .foregroundColor(AppColors.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.secondary)
                }
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .padding(.vertical, 2)
    }
}
