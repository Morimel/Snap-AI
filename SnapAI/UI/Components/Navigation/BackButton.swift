//
//  BackButton.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - BackButton
struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            AppImages.ButtonIcons.arrowRight
                .resizable()
                .frame(width: 12, height: 20)
                .rotationEffect(.degrees(180))
                .padding()
        }
    }
}
