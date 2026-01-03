#!/usr/bin/env python3
"""
Setup and Run Script for Materia Chemistry Model Training
Automates the entire pipeline from data preparation to CoreML conversion
"""

import subprocess
import sys
import os
import shutil

def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 8):
        print("❌ Python 3.8 or higher is required")
        sys.exit(1)
    print(f"✅ Python {sys.version_info.major}.{sys.version_info.minor} detected")

def install_requirements():
    """Install required packages"""
    print("📦 Installing required packages...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        print("✅ All packages installed successfully")
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install packages: {e}")
        sys.exit(1)

def run_data_preparation():
    """Run data preparation pipeline"""
    print("\n🔄 Running data preparation...")
    try:
        subprocess.check_call([sys.executable, "data_preparation.py"])
        print("✅ Data preparation completed")
    except subprocess.CalledProcessError as e:
        print(f"❌ Data preparation failed: {e}")
        sys.exit(1)

def run_model_training():
    """Run model training pipeline"""
    print("\n🔄 Running model training...")
    try:
        subprocess.check_call([sys.executable, "model_training.py"])
        print("✅ Model training completed")
    except subprocess.CalledProcessError as e:
        print(f"❌ Model training failed: {e}")
        sys.exit(1)

def run_iupac_setup():
    """Setup IUPAC naming engine"""
    print("\n🔄 Setting up IUPAC naming engine...")
    try:
        subprocess.check_call([sys.executable, "iupac_namer.py"])
        print("✅ IUPAC naming engine setup completed")
    except subprocess.CalledProcessError as e:
        print(f"❌ IUPAC setup failed: {e}")
        sys.exit(1)

def copy_models_to_ios():
    """Copy generated models to iOS project"""
    print("\n📁 Copying models to iOS project...")
    
    ios_coreml_dir = "../Materia/CoreMLModel"
    models_dir = "models"
    
    if not os.path.exists(ios_coreml_dir):
        print(f"⚠️  iOS CoreML directory not found: {ios_coreml_dir}")
        print("   Please copy the .mlpackage files manually to your iOS project")
        return
    
    # Copy .mlpackage files
    for filename in os.listdir(models_dir):
        if filename.endswith('.mlpackage'):
            src = os.path.join(models_dir, filename)
            dst = os.path.join(ios_coreml_dir, filename)
            
            if os.path.exists(dst):
                shutil.rmtree(dst)  # Remove existing
            
            shutil.copytree(src, dst)
            print(f"   ✅ Copied {filename}")
    
    # Copy preprocessing info
    preprocessing_files = ["preprocessing_info.json", "iupac_rules.json"]
    for filename in preprocessing_files:
        src = os.path.join(models_dir, filename)
        if os.path.exists(src):
            dst = os.path.join(ios_coreml_dir, filename)
            shutil.copy2(src, dst)
            print(f"   ✅ Copied {filename}")
    
    print("✅ Models copied to iOS project")

def print_next_steps():
    """Print next steps for iOS integration"""
    print("\n🎉 Model Training Pipeline Complete!")
    print("=" * 50)
    print("\n📱 Next Steps for iOS Integration:")
    print("1. Open your Xcode project")
    print("2. Add the new .mlpackage files to your project:")
    print("   - Materia_PropertyPredictor.mlpackage")
    print("   - Materia_StructureValidator.mlpackage")
    print("3. Update your CoreMLChemistryService.swift to use the new models")
    print("4. Test the app on device or simulator")
    print("\n📊 Model Performance:")
    print("- Property Predictor: Trained on molecular fingerprints")
    print("- Structure Validator: Binary classification for validity")
    print("- IUPAC Namer: Rule-based systematic naming")
    print("\n🔧 Files Generated:")
    print("- models/Materia_PropertyPredictor.mlpackage")
    print("- models/Materia_StructureValidator.mlpackage") 
    print("- models/preprocessing_info.json")
    print("- models/iupac_rules.json")

def main():
    """Main setup and run pipeline"""
    print("🧪 Materia Chemistry Model Training Pipeline")
    print("=" * 50)
    
    # Check environment
    check_python_version()
    
    # Install dependencies
    install_requirements()
    
    # Run pipeline
    run_data_preparation()
    run_model_training()
    run_iupac_setup()
    
    # Copy to iOS project
    copy_models_to_ios()
    
    # Print next steps
    print_next_steps()

if __name__ == "__main__":
    main()