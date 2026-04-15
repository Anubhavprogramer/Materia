//
//  ContentView.swift
//  Materia
//
//  Main navigation view for the chemistry app
//

import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                TabView {
            Tab ("Materia", systemImage: "plus.circle"){
                BuildTabView()
            }
            Tab ("Weight", systemImage: "scalemass.fill"){
                MolecularWeightCalculatorView()
            }
            Tab ("Live", systemImage: "person.2.wave.2"){
                ModePickerView()
            }
            Tab ("Saved", systemImage: "bookmark"){
                SavedCompoundsTabView()
            }
            Tab(role: .search){
                SearchTabView()
            }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
                .accentColor(AppColors.accent)
            }
        }
        .onAppear {
            // Show splash screen for 2 seconds then transition to main app
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

