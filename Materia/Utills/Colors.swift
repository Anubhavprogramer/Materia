//
//  Colors.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.


import SwiftUI
final class AppColors {
    
    // MARK: - Backgrounds
    static let background = Color("MateriaBackground")
    static let surface = Color("MateriaSurface")
    
    // MARK: - Brand Colors (Green Palette)
    static let primary = Color("MateriaPrimary")           // Vibrant green (#66CC99)
    static let secondary = Color("MateriaSecondary")       // Pale mint green
    static let accent = Color("MateriaAccent")             // Bright lime green
    
    // MARK: - Text Colors
    static let textPrimary = Color("MateriaTextPrimary")
    static let textSecondary = Color("MateriaTextSecondary")
    
    // MARK: - Feedback Colors
    static let error = Color("MateriaError")
    
    // MARK: - Component Colors
    static let carbon = Color("CarbonAtom")
    static let carbonTextColor = Color("CarbonTextColor")
    static let white = Color("white")
    
    // MARK: - Utility Colors (Green Theme Variants)
    static let primaryLight = primary.opacity(0.15)        // Light primary for backgrounds
    static let primaryMuted = primary.opacity(0.3)         // Muted primary for borders
    static let primaryFaded = primary.opacity(0.08)        // Faded primary for subtle backgrounds
    static let secondaryLight = secondary.opacity(0.15)    // Light secondary for backgrounds
    static let accentLight = accent.opacity(0.12)          // Light accent for backgrounds
    
    // MARK: - Gradient Colors
    static let gradientStart = background.opacity(0.95)
    static let gradientEnd = secondary.opacity(0.2)

}

