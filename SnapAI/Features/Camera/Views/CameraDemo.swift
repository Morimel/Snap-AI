//
//  CameraDemo.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

// MARK: - Demo
struct DemoRootView: View {
    @State private var showCamera = false
    @State private var lastShot: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            if let img = lastShot {
                Image(uiImage: img)
                    .resizable().scaledToFit()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
            } else {
                Text("No image yet").foregroundColor(.secondary)
            }

            Button("Open Camera") { showCamera = true }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundColor(.white)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
        }
        .padding()
        .fullScreenCover(isPresented: $showCamera) {
                    CameraFlow()   // <-- тут весь сценарий (камера -> детали)
                }
    }
}

#Preview("Main") {
    NavigationStack {
        DemoRootView().preferredColorScheme(.dark)
    }
}
