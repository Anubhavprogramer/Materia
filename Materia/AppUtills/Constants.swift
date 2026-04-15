//
//  Constants.swift
//  Materia
//
//  Centralized constants for strings, numbers, and configuration values

import Foundation
import UIKit

struct AppStrings {
    // MARK: - Navigation & Tabs
    static let AppName = "Materiya"
    static let search = "Search"
    static let weight = "Weight"
    static let live = "Live"
    static let saved = "Saved"
    
    // MARK: - Build Tab
    static let buildTabTitle = "Materia"
    static let buildSubtitle = "Chemical Structure Identifier"
    static let buildTip = "Tip"
    static let buildTipText = "Your saved compounds are available in the Saved tab."
    static let resetButton = "Reset"
    static let build = "Build Compound"
    
    // MARK: - Search Tab
    static let searchTitle = "Search"
    static let searchSubtitle = "Find compounds by name or formula"
    static let searchPrompt = "Name, formula..."
    static let searchCompoundsTitle = "Search Compounds"
    
    // MARK: - Saved Tab
    static let savedTitle = "Saved"
    static let savedCompounds = "Saved Compounds"
    static let noSavedCompounds = "No Saved Compounds"
    static let noSavedCompoundsMessage = "Build and save a compound from the Build tab."
    
    // MARK: - Compound Details
    static let compoundDetails = "Compound Details"
    static let doneButton = "Done"
    static let commonName = "Common Name"
    static let iupacName = "IUPAC Name"
    static let molecularFormula = "Molecular Formula"
    static let molarMass = "Molar Mass"
    static let category = "Category"
    static let description = "Description"
    static let physicalProperties = "Physical Properties"
    static let boilingPoint = "Boiling Point"
    static let meltingPoint = "Melting Point"
    static let density = "Density"
    static let preSaved = "Pre-saved"
    static let structureDetails = "Structure Details"
    static let carbonChainLength = "Carbon Chain Length"
    static let totalBonds = "Total Bonds"
    static let totalAtoms = "Total Atoms"
    static let carbonAtoms = "Carbon Atoms"
    static let functionalGroups = "Functional Groups"
    static let structureDiagram = "Structure Diagram"
    
    // MARK: - Compound Builder
    static let compoundBuilder = "Compound Builder"
    static let buildCompound = "Build Compound"
    static let identifyCompound = "Identify Compound"
    static let identifying = "Identifying..."
    static let carbonChain = "Carbon Chain"

    static let bondConfiguration = "Bond Configuration"
    static let noCarbonAtoms = "Add carbon atoms to start building"

    static let functionalGroupstext = "Add to Carbon at position :"
    static let validationStatus = "Validation Status"
    static let structurePreview = "Structure Preview"
    static let structureNotation = "Structure Notation:"

    static let structureAnalysis = "Structure Analysis"
    static let basicValidation = "Basic Validation"
    static let basicValidationMessage = "Structure follows basic chemistry rules"
    static let aiAnalysis = "AI Analysis"
    static let overallConfidence = "Overall Confidence"
    static let structureIssues = "Structure Issues"
    static let basicRules = "Basic Rules"
    static let basicRulesConfidence = "100%"
    static let aiAnalysisInProgress = "Analyzing structure with AI models..."
    static let aiAnalysisComplete = "Structure appears chemically feasible"
    static let aiAnalysisIssues = "Structure may have issues"
    static let aiAnalysisWaiting = "Waiting for structure analysis..."
    static let validationDetails = "Validation Details"
    static let molecularWeightInfo = "Molecular Weight Info"

    // MARK: - Toast Messages
    static let compoundSaved = "Compound saved successfully"
    static let compoundDeleted = "Compound deleted"
    static let compoundFailed = "Failed to save compound"
    static let errorOccurred = "Error occurred"
    static let loadingCompounds = "Loading compounds..."
    static let searchResults = "Search Results"
    static let noResults = "No Results Found"
    static let tryDifferentKeywords = "Try different keywords"
    
    // MARK: - Quick Start
    static let quickStart = "Quick Start"
    static let quickStartTemplates = "Tap an example to prefill the builder"
    static let ethanol = "Ethanol"
    static let ethene = "Ethene"
    static let ethyne = "Ethyne"
    static let aceticAcid = "Acetic Acid"

    // MARK: - Weight Calculator
    static let molecularWeightCalculator = "Molecular Weight"
    static let calculateWeight = "Calculate Weight"
    
    // MARK: - Collaboration
    static let collaboration = "Collaboration"
    static let modeSection = "Modes"
    static let collaborativeMoleculeBuilder = "Build with friend"
    static let teacherMode = "Teacher"
    static let studentMode = "Student"
    static let pairMode = "Pair Mode"

    // MARK: - Empty States
    static let startSearching = "Start Searching"
    static let enterCompoundName = "Enter a compound name or formula to get started"
    
    // MARK: - Indicators
    static let loading = "Loading..."
    static let preSavedIndicator = "Pre-saved"
    static let userCompound = "Your Compound"
    static let scroll = "scroll"
}
struct Tip {
    let title: String
    let message: String
    let icon: String
}
struct AppTips {
    static let savedTabTip = Tip(
        title: "Saved Tab",
        message: "Your saved compounds are available in the Saved tab.",
        icon: "bookmark.fill"
    )
    static let buildTabTip = Tip(
        title: "Your Chemistry Buddy",
        message: "Build and save compounds here. Your saved compounds will appear in the Saved tab.",
        icon: "none"
    )
    static let searchTabTip = Tip(
        title: "Search Tab",
        message: "Search for compounds by name or formula. Tap a result to view details.",
        icon: "magnifyingglass"
    )
    static let compoundDetailsTip = Tip(
        title: "Compound Details",
        message: "View detailed information about the compound, including its structure, properties, and identifiers.",
        icon: "info.circle"
    )
    static let molecularWeightTip = Tip(
        title: "Molecular Weight Calculator",
        message: "Calculate the molecular weight of a compound by entering its formula.",
        icon: "scalemass.fill"
    )
    static let collaborationTip = Tip(
        title: "info",
        message: "Offline-first. Nearby-only. No backend. \n\nAll sessions are encrypted using Multipeer Connectivity.",
        icon: "info.circle.fill"
    )
    
}

struct AppConstants {
    // MARK: - Numbers
    static let minCarbonChain = 1
    static let maxCarbonChain = 10
    static let animationDuration = 0.3
    static let collapseDuration = 0.2
    
    // MARK: - Font Sizes
    static let largeTitle: CGFloat = 32
    static let title: CGFloat = 20
    static let headline: CGFloat = 18
    static let subheadline: CGFloat = 16
    static let body: CGFloat = 14
    static let caption: CGFloat = 12
    
    // MARK: - Spacing
    static let defaultPadding: CGFloat = 16
    static let smallPadding: CGFloat = 12
    static let largePadding: CGFloat = 20
    
    // MARK: - Corner Radius
    static let defaultCornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 30

    // MARK: - Gap
    static let smallGap: CGFloat = 2
    static let defaultGap: CGFloat = 8
    static let mediumGap: CGFloat = 12
    static let largeGap: CGFloat = 16

    // MARK: - LineHeight
    static let defaultLineHeight: CGFloat = 1
    
    // MARK: - Toast Duration
    static let toastDuration: Double = 2.5
    static let toastAnimationDuration: Double = 0.3
    
    // MARK: - UserDefaults Keys
    static let savedCompoundsKey = "SavedCompounds"

    //MARK: - Carbon Attom Size
    static let carbonAtomSize: CGFloat = 32
    static let carbonAttomNumber = 10

    static let functionalGroupCardHeight: CGFloat = 32
    static let functionalGroupCardWidth: CGFloat = 40
}

struct AppIcons {
    static let checkmark = "checkmark.circle.fill"
    static let xmark = "xmark.circle.fill"
    static let brain = "brain.head.profile"
    static let exclamation = "exclamationmark.triangle.fill"
    static let bookmark = "bookmark.fill"
    static let magnifyingGlass = "magnifyingglass"
    static let info = "info.circle"
    static let bolt = "bolt.fill"
    static let plus = "plus.circle.fill"
    static let minus = "minus.circle.fill"
    static let cube = "cube.transparent"
}
