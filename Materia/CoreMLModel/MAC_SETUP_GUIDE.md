# Mac Setup Guide for ChemAI CoreML Models 🍎

## 🎯 Quick Setup for Your Mac

Since you have the iOS project on Mac and created models on Windows, here's the streamlined process:

## Step 1: Transfer Files to Mac 📁

### **Option A: Copy via USB/Cloud**
Copy the entire `coreml_models/` folder to your Mac:
```
coreml_models/
├── pytorch_models/          # Your trained models
├── convert_on_macos.py      # Mac conversion script
├── training_data.json       # Training data
├── model_metadata.json      # Model specs
└── iOS_Integration_Guide.md # Swift code examples
```

### **Option B: GitHub/Git Transfer**
```bash
# On Windows (if using git)
git add coreml_models/
git commit -m "Add CoreML models for iOS"
git push

# On Mac
git pull
```

## Step 2: Minimal Python Setup on Mac 🐍

### **Install Python & Dependencies**
```bash
# Install Python (if not already installed)
# Option 1: Using Homebrew (recommended)
brew install python

# Option 2: Download from python.org
# https://www.python.org/downloads/macos/

# Install only essential packages
pip3 install torch coremltools numpy
```

**That's it!** You don't need the full ChemAI backend on Mac - just these 3 packages.

## Step 3: Convert Models to CoreML 🔄

```bash
cd coreml_models
python3 convert_on_macos.py
```

This will create:
- `ChemAI_PropertyPredictor.mlmodel`
- `ChemAI_IupacNamer.mlmodel` 
- `ChemAI_StructureValidator.mlmodel`
- `ChemAI_ReactionPredictor.mlmodel`

## Step 4: Add to iOS Project 📱

### **In Xcode:**
1. Drag `.mlmodel` files into your iOS project
2. Make sure "Add to target" is checked
3. Models will be automatically compiled for iOS

### **Verify in Xcode:**
- Models should appear in Project Navigator
- Xcode auto-generates Swift classes like `ChemAI_PropertyPredictor`

## Step 5: Use in Swift Code 💻

### **Basic Integration:**
```swift
import CoreML

class ChemAIManager {
    private var propertyPredictor: ChemAI_PropertyPredictor?
    
    init() {
        loadModels()
    }
    
    private func loadModels() {
        do {
            propertyPredictor = try ChemAI_PropertyPredictor()
            print("✅ ChemAI models loaded successfully")
        } catch {
            print("❌ Error loading models: \(error)")
        }
    }
    
    func predictProperties(from smiles: String) -> [String: Float]? {
        guard let model = propertyPredictor else { return nil }
        
        // Convert SMILES to fingerprint (simplified example)
        let fingerprint = createFingerprint(from: smiles)
        
        do {
            let input = try MLMultiArray(shape: [1, 2048], dataType: .float32)
            for (index, value) in fingerprint.enumerated() {
                input[index] = NSNumber(value: value)
            }
            
            let prediction = try model.prediction(molecular_fingerprint: input)
            
            // Return predicted properties
            return [
                "molecular_weight": prediction.predicted_properties[0].floatValue,
                "logp": prediction.predicted_properties[1].floatValue,
                "solubility": prediction.predicted_properties[2].floatValue
                // ... more properties
            ]
        } catch {
            print("Prediction error: \(error)")
            return nil
        }
    }
    
    private func createFingerprint(from smiles: String) -> [Float] {
        // Simplified fingerprint creation
        // In production, you'd use a proper molecular fingerprint library
        var fingerprint = Array(repeating: Float(0), count: 2048)
        
        // Basic features from SMILES string
        fingerprint[0] = Float(smiles.count) // Length
        fingerprint[1] = Float(smiles.filter { $0 == "C" }.count) // Carbon count
        fingerprint[2] = Float(smiles.filter { $0 == "O" }.count) // Oxygen count
        fingerprint[3] = Float(smiles.filter { $0 == "N" }.count) // Nitrogen count
        
        // Add more sophisticated fingerprint logic here
        return fingerprint
    }
}
```

## 🚀 Quick Test in iOS

### **Test the Integration:**
```swift
// In your ViewController or SwiftUI View
let chemAI = ChemAIManager()

// Test with ethanol
if let properties = chemAI.predictProperties(from: "CCO") {
    print("Molecular Weight: \(properties["molecular_weight"] ?? 0)")
    print("LogP: \(properties["logp"] ?? 0)")
}
```

## 🔧 Troubleshooting

### **If Python/pip not found:**
```bash
# Check Python installation
python3 --version
pip3 --version

# If not found, install via Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install python
```

### **If CoreML conversion fails:**
```bash
# Try with specific versions
pip3 install torch==2.0.0 coremltools==7.0
```

### **If models don't load in iOS:**
- Check that `.mlmodel` files are in app bundle
- Verify iOS deployment target is 15.0+
- Check Xcode build logs for CoreML compilation errors

## 📱 Advanced iOS Features

### **Batch Processing:**
```swift
func predictMultipleCompounds(_ smilesArray: [String]) -> [[String: Float]] {
    return smilesArray.compactMap { predictProperties(from: $0) }
}
```

### **Async Predictions:**
```swift
func predictPropertiesAsync(from smiles: String) async -> [String: Float]? {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.predictProperties(from: smiles)
            continuation.resume(returning: result)
        }
    }
}
```

### **SwiftUI Integration:**
```swift
struct CompoundAnalyzer: View {
    @State private var smiles = "CCO"
    @State private var properties: [String: Float] = [:]
    private let chemAI = ChemAIManager()
    
    var body: some View {
        VStack {
            TextField("Enter SMILES", text: $smiles)
            Button("Analyze") {
                if let props = chemAI.predictProperties(from: smiles) {
                    properties = props
                }
            }
            
            ForEach(properties.sorted(by: <), id: \.key) { key, value in
                HStack {
                    Text(key)
                    Spacer()
                    Text("\(value, specifier: "%.2f")")
                }
            }
        }
    }
}
```

## ✅ Summary

**You only need:**
1. **3 Python packages** on Mac: `torch`, `coremltools`, `numpy`
2. **Run conversion script** once: `python3 convert_on_macos.py`
3. **Drag models to Xcode** and start coding!

**No need for:**
- Full ChemAI backend on Mac
- RDKit installation
- Complex Python environment

The models will work offline in your iPad app with excellent performance! 🚀