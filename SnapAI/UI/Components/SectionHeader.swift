//
//  SectionHeader.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Reusable pieces
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title2.weight(.semibold))
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }
}
