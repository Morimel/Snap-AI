//
//  Untitled.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

//MARK: - WeekStrip
struct WeekStrip: View {
    @Binding var selected: Date
    var calendar: Calendar = .current

    private var today: Date { calendar.startOfDay(for: Date()) }

    // текущие 7 дней: сегодня и следующие 6
//    private var days: [Date] {
//        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
//    }
    private var days: [Date] {
        (-3...3).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }


    private let monthFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = .current
        f.setLocalizedDateFormatFromTemplate("MMM")
        return f
    }()
    private let weekdayFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = .current
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f
    }()

    var body: some View {
        VStack(spacing: 6) {
            // Заголовок текущего месяца (по выбранному — это всегда сегодня)
            HStack {
                Text(monthFmt.string(from: today))
                    .font(.largeTitle).fontWeight(.semibold)
                    .foregroundColor(AppColors.primary.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal)

            // Бейджи месяцев для 7-дневного диапазона
            HStack(spacing: 0) {
                ForEach(days.indices, id: \.self) { i in
                    let d = days[i]
                    let isBoundary = (i == 0) ||
                        calendar.component(.month, from: d) != calendar.component(.month, from: days[i-1])

                    Text(isBoundary ? monthFmt.string(from: d) : " ")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(AppColors.primary.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(height: 16)

            // Ряд дней
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { d in
                    let isToday = calendar.isDate(d, inSameDayAs: today)

                    DayPill(
                        day: calendar.component(.day, from: d),
                        weekday: weekdayFmt.string(from: d),
                        selected: isToday
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .allowsHitTesting(isToday)      // остальные дни не кликабельны
                    .onTapGesture { if isToday { selected = d } }
                }
            }
        }
        .padding(.horizontal, 12)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { selected = today }            // всегда держим выбранным «сегодня»
    }
}
