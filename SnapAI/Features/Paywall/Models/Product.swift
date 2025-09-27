//
//  Product.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

enum Product: String, CaseIterable, Identifiable {
    case monthly, annual
    var id: Self { self }
    
    var title: String {
        switch self {
        case .monthly: return "Monthly plan"
        case .annual:  return "Annual plan"
        }
    }
    var price: String {
        switch self {
        case .monthly: return "$19.99"
        case .annual:  return "$59.99"
        }
    }
    var period: String {
        switch self {
        case .monthly: return "per month"
        case .annual:  return "per year"
        }
    }
    var badge: (text: String, foreground1: Color, background1: Color, foreground2: Color, background2: Color)? {
        switch self {
        case .monthly:
            return ("Popular", AppColors.primary, AppColors.primary.opacity(0.12), .white, AppColors.secondary
)
        case .annual:
            return ("Save 75%", AppColors.primary, AppColors.primary.opacity(0.12), .white, AppColors.secondary
)
        }
    }
}
