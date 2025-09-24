//
//  KcalField.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct KcalField: View {
    @Binding var kcal: Int

    var body: some View {
        TextField("kcal", text: Binding(
            get: { String(kcal) },
            set: { val in
                let digits = val.filter(\.isNumber)
                kcal = Int(digits) ?? 0
            }
        ))
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
        .frame(width: 70)
    }
}
