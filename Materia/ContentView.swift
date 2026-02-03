//
//  ContentView.swift
//  Materia
//
//  Main navigation view for the chemistry app
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            TabView {
                BuildTabView()
                    .tabItem {
                        Label("Materia", systemImage: "plus.circle")
                    }

                MolecularWeightCalculatorView()
                    .tabItem {
                        Label("Weight", systemImage: "scalemass.fill")
                    }

                CollaborationTabView()
                    .tabItem {
                        Label("Live", systemImage: "person.2.wave.2")
                    }

                SavedCompoundsTabView()
                    .tabItem {
                        Label("Saved", systemImage: "bookmark")
                    }
            }
            
            // Floating Search Button
            FloatingSearchButton()
        }
    }
}

#Preview {
    ContentView()
}
