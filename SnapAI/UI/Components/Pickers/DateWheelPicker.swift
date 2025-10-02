//
//  DateWheelPicker.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

struct DateWheelPicker: View {
    @Binding var selected: Date
    
    @State private var month: Int
    @State private var day: Int
    @State private var year: Int

    private let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    private let startYear = 1940
    private let years: [Int]
    
    @State private var dayStrings: [String]
    @State private var isSyncing = false


    init(selected: Binding<Date>) {
            _selected = selected

            let cal = Calendar.current
            let comps = cal.dateComponents([.year, .month, .day], from: selected.wrappedValue)

            let nowYear = cal.component(.year, from: Date())
            self.years = Array(startYear...nowYear)

            let y = comps.year ?? nowYear
            let m = (comps.month ?? 1) - 1
            let d = (comps.day ?? 1) - 1

            let yIndex = years.firstIndex(of: y) ?? (years.count - 1)
            _year = State(initialValue: yIndex)
            _month = State(initialValue: max(0, min(11, m)))

            let daysCount = DateWheelPicker.daysInMonth(monthIndex: m, year: years[yIndex])
            _dayStrings = State(initialValue: (1...daysCount).map { String(format: "%02d", $0) })
            _day = State(initialValue: max(0, min(daysCount - 1, d)))
        }

    var body: some View {
        HStack(spacing: 20) {
            /// MONTH
                        CustomWheelPicker(
                            items: months,
                            selectedIndex: $month,
                            columnWidth: 84
                        )
                        .tint(AppColors.primary)

            /// DAY
                        CustomWheelPicker(
                            items: dayStrings,
                            selectedIndex: $day,
                            columnWidth: 84
                        )
                        .tint(AppColors.primary)

            /// YEAR
                        CustomWheelPicker(
                            items: years.map { "\($0)" },
                            selectedIndex: $year,
                            columnWidth: 120
                        )
                        .tint(AppColors.primary)
        }
        .padding(.horizontal, 16)
        .onChange(of: month) { _ in recalcDaysAndPush() }
                .onChange(of: year)  { _ in recalcDaysAndPush() }
                .onChange(of: day)   { _ in pushSelected() }
    }
    
    private func recalcDaysAndPush() {
            let yVal = years[year]
            let daysCount = Self.daysInMonth(monthIndex: month, year: yVal)
            dayStrings = (1...daysCount).map { String(format: "%02d", $0) }
            if day >= daysCount { day = daysCount - 1 }
            pushSelected()
        }

        private func pushSelected() {
            var comps = DateComponents()
            comps.year = years[year]
            comps.month = month + 1
            comps.day = day + 1
            selected = Calendar.current.date(from: comps)!.atNoon()
        }
    
    private func syncFromSelected(_ date: Date) {
            isSyncing = true
            defer { isSyncing = false }

            let cal = Calendar.current
            let comps = cal.dateComponents([.year,.month,.day], from: date)

            let newYearIndex  = years.firstIndex(of: comps.year ?? years.last!) ?? (years.count - 1)
            let newMonthIndex = max(0, min(11, (comps.month ?? 1) - 1))
            let daysCount     = Self.daysInMonth(monthIndex: newMonthIndex, year: years[newYearIndex])
            let newDayIndex   = max(0, min(daysCount - 1, (comps.day ?? 1) - 1))

            year = newYearIndex
            month = newMonthIndex
            dayStrings = (1...daysCount).map { String(format: "%02d", $0) }
            day = newDayIndex
        }
    
    
    private static func daysInMonth(monthIndex: Int, year: Int) -> Int {
            var c = DateComponents()
            c.year = year
            c.month = monthIndex + 1
            let cal = Calendar.current
            let date = cal.date(from: c)!
            return cal.range(of: .day, in: .month, for: date)!.count
        }

    struct ColumnWidth: ViewModifier {
        var width: CGFloat
        func body(content: Content) -> some View { content.frame(width: width) }
    }
}

private struct DatePickerPreviewContainer: View {
    @State private var date = Date()
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            DateWheelPicker(selected: $date)
                .preferredColorScheme(.dark)
                .tint(AppColors.primary)
        }
    }
}

extension Date {
    func atNoon() -> Date {
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self) ?? self
    }
}

#Preview("Date picker") {
    DatePickerPreviewContainer()
}
