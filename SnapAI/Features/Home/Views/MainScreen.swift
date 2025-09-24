//
//  Untitled.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
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

