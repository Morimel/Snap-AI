//
//  BulletListBox.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - BulletListBox
struct BulletListBox: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(items, id: \.self) { text in
                    BulletRow(text: text)
                }
            }
            .padding(14)
        }
    }
}
