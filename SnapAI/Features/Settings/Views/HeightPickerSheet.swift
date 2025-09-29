//
//  HeightPickerSheet.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Height (ft/in)

struct HeightPickerSheet: View {
    @Binding var value: String
    @Environment(\.dismiss) private var dismiss

    @State private var feet: Int = 5
    @State private var inches: Int = 9

    private let feetRange = Array(3...7)
    private let inchRange = Array(0...11)

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                HStack {
                    Picker("Feet", selection: $feet) {
                        ForEach(feetRange, id: \.self) { Text("\($0) ft") }
                    }
                    Picker("Inches", selection: $inches) {
                        ForEach(inchRange, id: \.self) { Text("\($0) in") }
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 220)

                Text(formatted(feet: feet, inches: inches))
                    .font(.headline)
                Spacer()
            }
            .padding()
            .navigationTitle("Height")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        value = formatted(feet: feet, inches: inches)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            let parsed = parse(value)
            feet = parsed.feet
            inches = parsed.inches
        }
        .presentationDetents([.height(320)])
    }

    private func formatted(feet: Int, inches: Int) -> String {
        "\(feet)\'\(inches)\""
    }

    private func parse(_ s: String) -> (feet: Int, inches: Int) {
        let digits = s.split(whereSeparator: { !"0123456789".contains($0) }).compactMap { Int($0) }
        let f = digits.first ?? 5
        let i = digits.dropFirst().first ?? 9
        return (feet: min(max(f, feetRange.first!), feetRange.last!),
                inches: min(max(i, inchRange.first!), inchRange.last!))
    }
}
