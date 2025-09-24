//
//  String+Numbers.swift.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

extension String {
    var doubleValue: Double? {
        Double(self.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
