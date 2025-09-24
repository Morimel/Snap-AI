//
//  WeightPickerSheet.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Weight (lbs)
struct WeightPickerSheet: View {
    @Binding var value: String
    @Environment(\.dismiss) private var dismiss

    @State private var lbs: Int = 175
    private let range = Array(80...400)

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Weight", selection: $lbs) {
                    ForEach(range, id: \.self) { Text("\($0)") }
                }
                .pickerStyle(.wheel)
                .frame(height: 220)

                Text("\(lbs) lbs").font(.headline)
                Spacer()
            }
            .padding()
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        value = "\(lbs) lbs"
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let n = Int(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                lbs = n
            }
        }
        .presentationDetents([.height(300)])
    }
}
