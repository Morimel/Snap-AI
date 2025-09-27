//
//  DateWheelPicker.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct DateWheelPicker: View {
    // текущее состояние (индексы)
    @State private var month: Int
    @State private var day: Int
    @State private var year: Int

    // данные
    private let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    private let days = (1...31).map { String(format: "%02d", $0) }
    private let years: [String]

    // стартовый год в твоём диапазоне
    private let startYear = 1940

    init() {
        let now = Date()
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: now)

        // источники данных
        self.years = Array(startYear...currentYear).map(String.init)

        // начальные индексы (месяц/день необязательно, но наглядно)
        _month = State(initialValue: cal.component(.month, from: now) - 1) // 0...11
        _day   = State(initialValue: cal.component(.day,   from: now) - 1) // 0...30
        _year  = State(initialValue: currentYear - startYear)              // индекс текущего года
    }

    var body: some View {
        HStack(spacing: 20) {
            WheelPicker(selectedIndex: $month, count: months.count) { i, isSel in
                Text(months[i])
                    .font(.system(size: 22, weight: isSel ? .bold : .regular))
                    .foregroundColor(isSel ? .white : AppColors.primary)
                    .frame(maxWidth: .infinity)
            }

            WheelPicker(selectedIndex: $day, count: days.count) { i, isSel in
                Text(days[i])
                    .font(.system(size: 22, weight: isSel ? .bold : .regular))
                    .foregroundColor(isSel ? .white : AppColors.primary)
                    .frame(maxWidth: .infinity)
            }
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
        func body(content: Content) -> some View { content.frame(width: width) }
    }
}
