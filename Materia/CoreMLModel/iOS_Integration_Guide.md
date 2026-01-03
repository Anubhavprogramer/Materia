# iOS Integration Guide for ChemAI CoreML Models

## Quick Start

1. Copy the `.mlmodel` files to your iOS project
2. Add them to your Xcode project bundle
3. Use the following Swift code to integrate:

```swift
import CoreML
import Foundation

class ChemAIManager {
    private var propertyPredictor: ChemAI_PropertyPredictor?
    private var structureValidator: ChemAI_StructureValidator?
    
    init() {
        loadModels()
    }
    
    private func loadModels() {
        do {
            propertyPredictor = try ChemAI_PropertyPredictor(configuration: MLModelConfiguration())
            structureValidator = try ChemAI_StructureValidator(configuration: MLModelConfiguration())
        } catch {
            print("Error loading models: \(error)")
        }
    }
    
    func predictProperties(fingerprint: [Float]) -> [Float]? {
        guard let model = propertyPredictor else { return nil }
        
        do {
            let input = try MLMultiArray(shape: [1, 2048], dataType: .float32)
            for (index, value) in fingerprint.enumerated() {
                input[index] = NSNumber(value: value)
            }
            
            let prediction = try model.prediction(input: input)
            // Process prediction results
            return Array(prediction.output)
        } catch {
            print("Prediction error: \(error)")
            return nil
        }
    }
    
    func validateStructure(features: [Float]) -> Bool {
        guard let model = structureValidator else { return false }
        
        do {
            let input = try MLMultiArray(shape: [1, 50], dataType: .float32)
            for (index, value) in features.enumerated() {
                input[index] = NSNumber(value: value)
            }
            
            let prediction = try model.prediction(input: input)
            // Return true if valid (index 1 > index 0)
            return prediction.output[1].floatValue > prediction.output[0].floatValue
        } catch {
            print("Validation error: \(error)")
            return false
        }
    }
}
```

## Model Specifications

### Property Predictor
- **Input**: 2048-dimensional molecular fingerprint
- **Output**: 10 predicted properties
- **Properties**: MW, LogP, HBD, HBA, RotBonds, TPSA, AromaticRings, LargeMol, Lipophilic, HBondFlag

### Structure Validator
- **Input**: 50-dimensional structure features
- **Output**: 2-class probability (invalid, valid)
- **Usage**: Validate molecular structures before processing

## Integration Tips

1. **Preprocessing**: Convert SMILES to fingerprints using RDKit or similar
2. **Error Handling**: Always check model loading and prediction errors
3. **Performance**: Models are optimized for iOS Neural Engine when available
4. **Memory**: Models are designed to be memory-efficient for mobile use

## Example App Structure

```
ChemAI iOS App/
├── Models/
│   ├── ChemAI_PropertyPredictor.mlmodel
│   └── ChemAI_StructureValidator.mlmodel
├── Services/
│   ├── ChemAIManager.swift
│   └── MolecularProcessor.swift
├── Views/
│   ├── CompoundInputView.swift
│   └── ResultsView.swift
└── Utils/
    └── ChemicalUtils.swift
```
