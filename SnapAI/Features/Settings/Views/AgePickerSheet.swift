//
//  AgePickerSheet.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Age
struct AgePickerSheet: View {
    @Binding var value: String
    @Environment(\.dismiss) private var dismiss

    @State private var ageInt: Int = 27
    private let range = Array(10...100)

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Age", selection: $ageInt) {
                    ForEach(range, id: \.self) { Text("\($0)") }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 220)

                Text("\(ageInt) years old")
                    .font(.headline)
                    .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle("Age")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        value = "\(ageInt) years old"
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let n = Int(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                ageInt = n
            }
        }
        .presentationDetents([.height(300)])
    }
}
