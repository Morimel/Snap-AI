//
//  UnitTextField.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - UnitTextField
struct UnitTextField: View {
    @ObservedObject var vm: OnboardingViewModel   
    let placeholder: String
    @Binding var text: String
    
    enum Kind { case weight, height }
    
    let kind: Kind
    
    private var unit: String {
        switch kind {
        case .weight: return vm.data.unit == .imperial ? "lbs" : "kg"
        case .height: return vm.data.unit == .imperial ? "ft"  : "cm"
        }
    }
    
    var body: some View {
        HStack {
            TextField(
                "", text: $text,
                prompt: styledPlaceholder(placeholder, color: AppColors.primary.opacity(0.35))
            )
            .keyboardType(.decimalPad)
            .foregroundStyle(AppColors.primary)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            
            Text(unit)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.primary)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
        .onChange(of: text) { v in
            let filtered = v.filter { "0123456789.,".contains($0) }
            if filtered != v { text = filtered }
        }
    }
}


func styledPlaceholder(_ text: String, color: Color) -> Text {
    if #available(iOS 17, *) {
        return Text(text).foregroundStyle(color)
    } else {
        return Text(text).foregroundColor(color)
    }
}

extension View {
    @ViewBuilder
    func fgCompat(_ color: Color) -> some View {
        if #available(iOS 17, *) {
            self.foregroundStyle(color)
        } else {
            self.foregroundColor(color)
        }
    }
}


