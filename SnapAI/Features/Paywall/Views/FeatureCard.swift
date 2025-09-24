//
//  FeatureCard.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - FeatureCard
struct FeatureCard: View {
    let features: [Features]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features.indices, id: \.self) { i in
                FeatureRow(feature: features[i])
            }
        }
    }
}

