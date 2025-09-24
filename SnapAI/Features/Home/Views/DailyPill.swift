//
//  DailyPill.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - DayPill
struct DayPill: View {
    let day: Int
    let weekday: String
    let selected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(day)")
                .font(.system(size: 22, weight: .bold))
            Text(weekday)
                .font(.system(size: 14, weight: .regular))
        }
        .foregroundStyle(selected ? Color.white : AppColors.primary)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(selected ? AppColors.primary : Color.clear)
                .frame(width: 32)
        )
    }
}
