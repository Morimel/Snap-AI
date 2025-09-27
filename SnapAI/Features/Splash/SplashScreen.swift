//
//  SplashScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 24/9/25.
//

import SwiftUI

struct SplashScreen: View {
    
    @State var animationValues: [Bool] = Array(repeating: false, count: 10)
    
    @State private var offsetAmount: CGFloat = 0
    
    var body: some View {
        ZStack {
            
            LinearGradient(stops: [
                .init(color: AppColors.secondary,       location: 0.10),
                .init(color: AppColors.splashBackground, location: 0.45)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            ZStack {
                if animationValues[1] {
                    AppImages.OtherImages.splashBack
                        .offset(x: animationValues[2] ? -25 : -10, y: -120)
                }
                
                AppImages.OtherImages.avocado
                    .resizable()
                    .scaledToFill()
                    .frame(width: 400, height: 400)
                    .offset(x: 330, y: -100)
                    .offset(x: animationValues[0] ? -200 : 0)
                
                
                VStack  {
                    Spacer()
                    
                    (Text("Snap ")
                        .foregroundColor(.white) +
                     Text("AI")
                        .foregroundColor(AppColors.secondary))
                    .font(.system(size: 40, weight: .bold, design: .default))
                    
                    Text("Ultimate Food Tracker")
                        .foregroundStyle(AppColors.surface)
                        .font(.system(size: 16, weight: .light, design: .default))
                    
                    LineProgressBar()
                }
                .padding(.vertical, 30)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                animationValues[0] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animationValues[1] = true
                
                withAnimation(.easeInOut(duration: 2).delay(0.1)) {
                    animationValues[2] = true
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
}
