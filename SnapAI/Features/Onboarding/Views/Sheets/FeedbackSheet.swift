//
//  FeedbackSheet.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - FeedbackSheet
struct FeedbackSheet: View {
    let rating: Int
    var onSend: (String) -> Void
    var onSkip: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What could we improve?")
                    .font(.headline)
                
                TextEditor(text: $text)
                    .frame(minHeight: 140)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                Button {
                    dismiss()
                    onSend(text.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    Text("Send feedback")
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundColor(.white)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    dismiss()
                    onSkip()
                } label: {
                    Text("Skip")
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundColor(AppColors.primary)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .navigationTitle("Your feedback")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
