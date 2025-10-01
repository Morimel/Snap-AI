//
//  FeedbackSheet.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - PrettyTextEditor (плейсхолдер, рамка, счётчик, Done)
struct PrettyTextEditor: View {
    @Binding var text: String
    var placeholder: String = "Write something…"
    var limit: Int? = 250
    var minHeight: CGFloat = 140
    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(focused ? AppColors.primary : Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 10, y: 6)

            TextEditor(text: Binding(
                get: { text },
                set: { new in
                    if let limit { text = String(new.prefix(limit)) } else { text = new }
                })
            )
            .background(.white)
            .focused($focused)
            .scrollContentBackground(.hidden)
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .tint(AppColors.primary)
            .padding(14)
            .frame(minHeight: minHeight)
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if let limit {
                    Text("\(text.count)/\(limit)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

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
                    .foregroundStyle(AppColors.primary)
                    .font(.headline)
                
                PrettyTextEditor(
                                    text: $text,
                                    placeholder: "Tell us what was confusing, annoying, or missing…",
                                    limit: 500,
                                    minHeight: 140
                                )
                
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
            .background(AppColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your feedback")
                    
                        .font(.headline)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


#Preview {
    FeedbackSheet(rating: 3, onSend: { _ in }, onSkip: { })
}
