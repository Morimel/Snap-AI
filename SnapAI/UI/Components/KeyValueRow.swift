//
//  KeyValueRow.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - KeyValueRow
struct KeyValueRow: View {
    let key: String
    let value: String
    var body: some View {
        HStack {
            Text(key)
                .font(.headline.weight(.semibold))
                .foregroundColor(AppColors.primary)
            Spacer(minLength: 16)
            Text(value)
                .font(.callout)
                .foregroundColor(AppColors.primary)
        }
        .frame(height: 54)
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
    }
}
