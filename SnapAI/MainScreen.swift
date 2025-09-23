//
//  MainScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 20/9/25.
//

import SwiftUI


//MARK: - MainScreen
struct MainScreen: View {
    
    @State private var selected = Date() // сегодня
    
    var onNext: (() -> Void)? = nil
    
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack {
                // пример: неделя, где попадаем на «29 Aug → 4 Sep»
                let ref = Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 29))!
                WeekStrip(selected: $selected, reference: ref)
                
                StatisticsCard()
                
                HStack {
                    Text("History")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .padding()
                    
                    Spacer()
                }
                EpmtyCardView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            StickyPlusButton() {
                showCamera = true    // действие по кнопке
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Snap AI")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 24, weight: .semibold))
            }
            
            ToolbarItem {
                Button {
                    print("gfd")
                } label: {
                    AppImages.ButtonIcons.gear
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                }
                
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraScreen { image in
                capturedImage = image      // сохраним если нужно
                showCamera = false         // закрыть камеру
                // здесь можно перейти на экран с добавлением блюда:
                // path.append(Route.addMeal(image))
            }
            .statusBarHidden(true)         // опционально
        }
    }
}


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



//MARK: - DayPill
private struct DayPill: View {
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


//MARK: - StatisticsCard
struct StatisticsCard: View {
    var body: some View {
        
        let kcal = 1758
        
        let kcalNeeded = 2569
        
        let kcalSpent = 811
        
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 10)
                    .frame(width: 150, height: 150)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.white, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottomLeading))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 10, y: 10)
                
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(lineWidth: 10)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.customBlue]), startPoint: .top, endPoint: .bottomLeading))
                
                Circle()
                    .stroke(lineWidth: 10)
                    .frame(width: 196, height: 196)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.white, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottomLeading))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 10, y: 10)
                
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(lineWidth: 10)
                    .frame(width: 196, height: 196)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.customOrange]), startPoint: .top, endPoint: .bottomLeading))
                
                
                Circle()
                    .stroke(lineWidth: 14)
                    .frame(width: 240, height: 240)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.white, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottomLeading))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 10, y: 10)
                
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(lineWidth: 14)
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [AppColors.customGreen]), startPoint: .top, endPoint: .bottomLeading))
                
                VStack {
                    Text("\(kcal)")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 28, weight: .bold, design: .default))
                    
                    Text("kcal")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 14, weight: .regular, design: .default))
                }
            }
            .padding(.top, 20)
            HStack {
                VStack {
                    Text("\(kcalNeeded)")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 20, weight: .bold, design: .default))
                    
                    Text("Need it today")
                        .foregroundStyle(AppColors.secondary)
                        .font(.system(size: 12, weight: .regular, design: .default))
                }
                .padding(.horizontal, 36)
                
                
                VStack {
                    Text("\(kcalSpent)")
                        .foregroundStyle(AppColors.primary)
                        .font(.system(size: 20, weight: .bold, design: .default))
                    
                    Text("Already spent")
                        .foregroundStyle(AppColors.secondary)
                        .font(.system(size: 12, weight: .regular, design: .default))
                }
                .padding(.horizontal, 36)
            }
            
            MacroSummaryCard(
                protein: (150, 220),
                fat:     (56,  88),
                carb:    (150, 220)
            )
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding()
    }
}


//MARK: - MacroSummaryCard
struct MacroSummaryCard: View {
    let protein: (current: Double, target: Double)
    let fat:     (current: Double, target: Double)
    let carb:    (current: Double, target: Double)
    
    var body: some View {
        HStack(spacing: 20) {
            MacroBar(title: "Proteins",
                     current: protein.current, target: protein.target,
                     gradient: LinearGradient(gradient: Gradient(colors: [AppColors.customGreen, AppColors.primary]),
                                              startPoint: .leading, endPoint: .trailing))
            
            MacroBar(title: "Fats",
                     current: fat.current, target: fat.target,
                     gradient: LinearGradient(gradient: Gradient(colors: [AppColors.customBlue, AppColors.primary]),
                                              startPoint: .leading, endPoint: .trailing))
            
            MacroBar(title: "Carbohydrates",
                     current: carb.current, target: carb.target,
                     gradient: LinearGradient(gradient: Gradient(colors: [AppColors.customOrange, AppColors.primary]),
                                              startPoint: .leading, endPoint: .trailing))
        }
        .padding(20)
    }
}


//MARK: - MacroBar
private struct MacroBar: View {
    let title: String
    let current: Double
    let target: Double
    let gradient: LinearGradient
    
    private let barHeight: CGFloat = 6
    private let knobSize: CGFloat = 8
    
    var fraction: CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(min(max(current / target, 0), 1))
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.primary)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: barHeight)
                    
                    // заполнение
                    Capsule()
                        .fill(gradient)
                        .frame(width: geo.size.width * fraction, height: barHeight)
                    
                    // «ползунок»-индикатор
                    Circle()
                        .fill(.white)
                        .overlay(
                            Circle().stroke(Color.black.opacity(0.35), lineWidth: 1)
                        )
                        .frame(width: knobSize, height: knobSize)
                        .offset(x: max(0, (geo.size.width - knobSize) * fraction))
                }
                .animation(.easeInOut(duration: 0.25), value: fraction)
            }
            .frame(height: knobSize)
            
            Text("\(Int(current)) / \(Int(target))g")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppColors.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


//MARK: - EpmtyCardView
struct EpmtyCardView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Nothing here yet!")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 16, weight: .bold))
                    .padding(.vertical)
                
                Text("Add something delicious\nand treat yourself to a new\ndish!")
                    .foregroundStyle(AppColors.primary)
                    .font(.system(size: 14, weight: .medium))
            }
            
            .padding()
            
            AppImages.Other.plateApple
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white)
            
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal)
        
    }
}


//MARK: - StickyPlusButton
//struct StickyPlusButton: View {
//    let action: () -> Void
//
//    var body: some View {
////                .foregroundStyle(AppColors.secondary)
////                .frame(width: 90, height: 64)
//
//            Button {
//                print("dvdfv")
//            } label: {
//                AppImages.ButtonIcons.Plus.lightPlus
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 20, height: 20)
//            }
//            .frame(width: 80, height: 56)
//            .background(
//                Capsule()
//                    .fill(AppColors.secondary)
//            )
//            .ignoresSafeArea(edges: .bottom)
//
//
//    }
//}


struct StickyPlusButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {                    // 👈 вызываем action()
            AppImages.ButtonIcons.Plus.lightPlus
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(.vertical, 18)             // побольше кликабельная зона
        }
        .frame(width: 80, height: 56)
        .background(Capsule().fill(AppColors.secondary))
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
    }
}




#Preview {
    NavigationStack {
        MainScreen()
    }
}

