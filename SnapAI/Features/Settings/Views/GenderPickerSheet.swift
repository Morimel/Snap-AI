//
//  GenderPickerSheet.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Gender

struct GenderPickerSheet: View {
    @Binding var value: String
    @Environment(\.dismiss) private var dismiss

    private let options = ["Male", "Female", "Other"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(options, id: \.self) { option in
                    Button {
                        value = option
                        dismiss()
                    } label: {
                        HStack {
                            Text(option)
                            Spacer()
                            if option == value {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Gender")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
