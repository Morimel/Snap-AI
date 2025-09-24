//
//  FeatureRow.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - FeatureRow
struct FeatureRow: View {
    let feature: Features
    var body: some View {
        HStack( spacing: 12) {
            feature.image
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            
            
            Text(feature.title)
                .font(.system(size: 16))
                .foregroundStyle(.white)
        }
    }
}
