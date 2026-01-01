# Materia - Chemical Structure Identifier

A comprehensive iOS chemistry app built with SwiftUI that identifies chemical compounds from molecular structures. Perfect for chemistry students and educators.

## 🧪 Features

### Core Functionality
- **Compound Builder**: Interactive form-based molecular structure builder
- **Structure Visualization**: Real-time 2D molecular diagrams
- **Compound Identification**: AI-powered compound naming and classification
- **Compound Library**: Save and manage identified compounds

### Structure Input Methods
1. **Visual Structure Builder** (Primary)
   - Carbon chain configuration (1-10 carbons)
   - Bond type selection (single, double, triple)
   - Functional group attachment
   - Real-time validation

2. **Touch-based Drawing** (Planned)
   - Direct molecular drawing interface
   - Atom and bond placement

3. **Image Upload** (Planned)
   - Skeletal diagram recognition
   - Structure extraction from images

## 🏗️ Architecture

### SwiftUI + MVVM Pattern
- **Models**: `ChemicalStructure`, `IdentifiedCompound`, `Bond`, `FunctionalGroup`
- **ViewModels**: `CompoundBuilderViewModel`, `HomeViewModel`
- **Views**: Modular SwiftUI components for each screen

### Key Components

#### Data Models
- `ChemicalStructure`: Core molecular representation
- `Bond`: Carbon-carbon bond configuration
- `FunctionalGroupAttachment`: Functional group positioning
- `IdentifiedCompound`: Complete compound with metadata

#### ViewModels
- `CompoundBuilderViewModel`: Handles structure building logic
- `HomeViewModel`: Manages compound library and persistence

#### Views
- `HomeView`: Main screen with compound library
- `CompoundBuilderView`: Interactive structure builder
- `CompoundResultView`: Compound identification results
- `StructurePreviewSection`: 2D molecular visualization

## 🧬 Chemistry Features

### Supported Functional Groups
- **Alkyl**: Methyl (CH₃)
- **Alcohols**: Hydroxyl (OH)
- **Amines**: Amino (NH₂)
- **Carboxylic Acids**: Carboxyl (COOH)
- **Aldehydes**: Formyl (CHO)
- **Ketones**: Carbonyl (CO)
- **Nitriles**: Cyano (CN)
- **Nitro Groups**: Nitro (NO₂)
- **Thiols**: Sulfhydryl (SH)
- **Halogens**: F, Cl, Br, I

### Bond Types
- Single bonds (C—C)
- Double bonds (C=C)
- Triple bonds (C≡C)

### Validation Rules
- Carbon valency enforcement (max 4 bonds)
- Chemical feasibility checking
- Real-time error feedback

## 🎯 Compound Identification

### AI-Powered Naming
- Common name preference (e.g., "Ethanol" vs "Ethyl alcohol")
- IUPAC nomenclature support
- Functional group priority rules
- Molecular formula calculation

### Supported Compound Classes
- **Alkanes**: Methane, Ethane, Propane, etc.
- **Alcohols**: Methanol, Ethanol, Propanol, etc.
- **Carboxylic Acids**: Formic, Acetic, Propanoic, etc.
- **Aldehydes**: Formaldehyde, Acetaldehyde, etc.
- **Ketones**: Acetone, Butanone, etc.
- **Amines**: Methylamine, Ethylamine, etc.

## 📱 User Experience

### Clean, Educational Interface
- Chemistry-first design principles
- Immediate validation feedback
- Progressive disclosure of complexity
- Student-friendly terminology

### Workflow
1. **Build**: Create molecular structure using form controls
2. **Validate**: Real-time chemical feasibility checking
3. **Identify**: AI-powered compound identification
4. **Save**: Store compounds in personal library

## 🛠️ Technical Implementation

### Technologies
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **UserDefaults**: Local compound persistence
- **Apple Intelligence**: Compound identification (simulated)

### Code Quality
- MVVM architecture pattern
- Comprehensive data validation
- Modular, reusable components
- Clean, documented code

### Performance
- Efficient 2D rendering
- Optimized structure calculations
- Smooth animations and transitions
- Memory-conscious design

## 🎓 Educational Value

### Learning Objectives
- Molecular structure understanding
- Chemical nomenclature mastery
- Functional group recognition
- Bond type comprehension

### Use Cases
- **Students**: Learn organic chemistry concepts
- **Educators**: Demonstrate molecular structures
- **Researchers**: Quick compound identification
- **Hobbyists**: Explore chemical structures

## 🚀 Getting Started

### Requirements
- iOS 18.5+
- Xcode 16.4+
- Swift 5.0+

### Installation
1. Clone the repository
2. Open `Materia.xcodeproj` in Xcode
3. Build and run on iOS Simulator or device

### Usage
1. Launch the app
2. Tap "Build Compound"
3. Configure carbon chain length
4. Set bond types between carbons
5. Add functional groups
6. Tap "Identify Compound"
7. View results and save to library

## 🔬 Future Enhancements

### Planned Features
- Touch-based molecular drawing
- Image recognition for skeletal structures
- Advanced IUPAC naming rules
- 3D molecular visualization
- Reaction mechanism builder
- Compound property database

### Technical Improvements
- Core Data integration
- CloudKit synchronization
- Advanced AI integration
- Performance optimizations

## 📄 License

This project is designed for educational purposes and chemistry learning.

## 🤝 Contributing

Built as a Swift Student Challenge submission demonstrating:
- Advanced SwiftUI techniques
- MVVM architecture
- Chemistry domain knowledge
- Educational app design
- Clean code principles

---

**Materia** - Making chemistry accessible through technology 🧪✨# Materia
