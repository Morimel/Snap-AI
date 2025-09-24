//
//  TipRow.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - TipRow
struct TipRow: View {
    let tip: Tip

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            tip.image
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .padding()
                .accessibilityHidden(true)


            VStack(alignment: .leading, spacing: 6) {
                Text(tip.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

                Text(tip.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
