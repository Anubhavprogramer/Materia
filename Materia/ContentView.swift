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
            BuildTabView()
                .tabItem {
                    Label("Materia", systemImage: "plus.circle")
                }

            CollaborationTabView()
                .tabItem {
                    Label("Live", systemImage: "person.2.wave.2")
                }

            MolecularWeightCalculatorView()
                .tabItem {
                    Label("Weight", systemImage: "scalemass.fill")
                }

            SavedCompoundsTabView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
        }
    }
}

#Preview {
    ContentView()
}
