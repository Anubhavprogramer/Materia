//
//  ContentView.swift
//  Materia
//
//  Main navigation view for the chemistry app
//

import SwiftUI

struct ContentView: View {
    var body: some View {
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

