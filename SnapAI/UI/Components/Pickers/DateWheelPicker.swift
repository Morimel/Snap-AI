//
//  DateWheelPicker.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct DateWheelPicker: View {
    @State private var month = 0
    @State private var day = 0        // 0 -> "01"
    @State private var year = 2
    
    private let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    private let days = (1...31).map { String(format: "%02d", $0) }
    private let years = (1940...Calendar.current.component(.year, from: Date())).map(String.init)
    
    var body: some View {
        HStack(spacing: 20) {
            WheelPicker(selectedIndex: $month, count: months.count) { i, isSel in
                Text(months[i])
                    .font(.system(size: 22, weight: isSel ? .bold : .regular))
                    .foregroundColor(isSel ? .white : AppColors.primary)
                    .frame(maxWidth: .infinity)
            }
            
            WheelPicker(selectedIndex: $day, count: days.count,
                        row: { i, isSel in
                Text(days[i])
                    .font(.system(size: 22, weight: isSel ? .bold : .regular))
                    .foregroundColor(isSel ? .white : AppColors.primary)
                    .frame(maxWidth: .infinity)
            })
            .modifier(ColumnWidth(width: 100))
            
            WheelPicker(selectedIndex: $year, count: years.count) { i, isSel in
                Text(years[i])
                    .font(.system(size: 22, weight: isSel ? .bold : .regular))
                    .foregroundColor(isSel ? .white : AppColors.primary)
                    .frame(maxWidth: .infinity)
            }
            .modifier(ColumnWidth(width: 130))
        }
        .padding(.horizontal, 16)
    }
    
    struct ColumnWidth: ViewModifier {
        var width: CGFloat
        func body(content: Content) -> some View {
            content.frame(width: width)
        }
    }
}
