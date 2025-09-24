//
//  BulletRow.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - BulletRow
struct BulletRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("•")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.primary)
                .padding(.top, 2) // чуть опустить, чтобы по базовой линии красиво

            // текст с переносами и ровным отступом
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.primary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
