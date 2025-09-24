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
    var reference: Date
    var calendar: Calendar = .current
    
    private var weekDays: [Date] {
        let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
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
            
            HStack {
                Text(monthFmt.string(from: selected))
                    .font(.largeTitle).fontWeight(.semibold)
                    .foregroundColor(AppColors.primary.opacity(0.9))
                
                Spacer()
            }
            .padding(.horizontal)
            
            // ✅ Бейджи месяцев: НЕТ Spacer, фиксируем небольшую высоту
            HStack(spacing: 0) {
                ForEach(weekDays.indices, id: \.self) { i in
                    let d = weekDays[i]
                    let isBoundary = (i == 0) ||
                    calendar.component(.month, from: d) != calendar.component(.month, from: weekDays[i-1])
                    
                    Text(isBoundary ? monthFmt.string(from: d) : " ")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(AppColors.primary.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(height: 16) // чтобы ряд не «раздувался»
            
            // Строка дней
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { d in
                    DayPill(
                        day: calendar.component(.day, from: d),
                        weekday: weekdayFmt.string(from: d),
                        selected: calendar.isDate(d, inSameDayAs: selected)
                    )
                    .onTapGesture { selected = d }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 12)
        .fixedSize(horizontal: false, vertical: true) // не занимать лишнюю высоту
    }
}
