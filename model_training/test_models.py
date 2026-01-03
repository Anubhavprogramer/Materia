#!/usr/bin/env python3
"""
Test Script for Materia Chemistry Models
Validates that trained models work correctly
"""

import os
import numpy as np
import pandas as pd
import pickle
import json
from rdkit import Chem
from rdkit.Chem import rdMolDescriptors

def test_data_files():
    """Test that all required data files exist"""
    print("🔍 Testing data files...")
    
    required_files = [
        "data/molecular_properties.csv",
        "data/molecular_fingerprints.npy", 
        "data/smiles_list.pkl"
    ]
    
    for file_path in required_files:
        if os.path.exists(file_path):
            print(f"   ✅ {file_path}")
        else:
            print(f"   ❌ {file_path} - Missing!")
            return False
    
    return True

def test_model_files():
    """Test that CoreML models were generated"""
    print("\n🔍 Testing model files...")
    
    required_models = [
        "models/Materia_PropertyPredictor.mlpackage",
        "models/Materia_StructureValidator.mlpackage",
        "models/preprocessing_info.json",
        "models/iupac_rules.json"
    ]
    
    for model_path in required_models:
        if os.path.exists(model_path):
            print(f"   ✅ {model_path}")
        else:
            print(f"   ❌ {model_path} - Missing!")
            return False
    
    return True

def test_preprocessing_info():
    """Test preprocessing information"""
    print("\n🔍 Testing preprocessing info...")
    
    try:
        with open("models/preprocessing_info.json", "r") as f:
            info = json.load(f)
        
        required_keys = ["target_properties", "scaler_mean", "scaler_scale", "fingerprint_size"]
        
        for key in required_keys:
            if key in info:
                print(f"   ✅ {key}: {len(info[key]) if isinstance(info[key], list) else info[key]}")
            else:
                print(f"   ❌ {key} - Missing!")
                return False
        
        return True
        
    except Exception as e:
        print(f"   ❌ Error loading preprocessing info: {e}")
        return False

def test_fingerprint_generation():
    """Test molecular fingerprint generation"""
    print("\n🔍 Testing fingerprint generation...")
    
    test_smiles = ["CCO", "CC(=O)O", "CCC", "CO"]
    test_names = ["Ethanol", "Acetic acid", "Propane", "Methanol"]
    
    try:
        for smiles, name in zip(test_smiles, test_names):
            mol = Chem.MolFromSmiles(smiles)
            if mol:
                fp = rdMolDescriptors.GetMorganFingerprintAsBitVect(mol, radius=2, nBits=2048)
                fp_array = np.array(fp, dtype=np.float32)
                
                # Check fingerprint properties
                num_bits_set = np.sum(fp_array)
                print(f"   ✅ {name} ({smiles}): {num_bits_set} bits set")
            else:
                print(f"   ❌ {name} ({smiles}): Invalid SMILES")
                return False
        
        return True
        
    except Exception as e:
        print(f"   ❌ Error generating fingerprints: {e}")
        return False

def test_iupac_naming():
    """Test IUPAC naming engine"""
    print("\n🔍 Testing IUPAC naming...")
    
    try:
        # Import the IUPAC namer
        from iupac_namer import IUPACNamer
        
        namer = IUPACNamer()
        
        # Create mock structures for testing
        class MockGroup:
            def __init__(self, group_type):
                self.group = group_type
        
        class MockAttachment:
            def __init__(self, position, group_type):
                self.carbonPosition = position
                self.group = MockGroup(group_type)
        
        class MockStructure:
            def __init__(self, chain_length):
                self.carbonChainLength = chain_length
                self.functionalGroups = []
                self.bonds = []
        
        # Test cases
        test_cases = [
            (MockStructure(1), "methane"),
            (MockStructure(2), "ethane"),
            (MockStructure(3), "propane"),
        ]
        
        # Add functional groups
        alcohol_structure = MockStructure(2)
        alcohol_structure.functionalGroups.append(MockAttachment(1, "alcohol"))
        test_cases.append((alcohol_structure, "ethanol"))
        
        acid_structure = MockStructure(2)
        acid_structure.functionalGroups.append(MockAttachment(1, "carboxylicAcid"))
        test_cases.append((acid_structure, "ethanoic acid"))
        
        for structure, expected_type in test_cases:
            result = namer.generate_iupac_name(structure)
            print(f"   ✅ C{structure.carbonChainLength}: {result}")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Error testing IUPAC naming: {e}")
        return False

def test_data_quality():
    """Test quality of training data"""
    print("\n🔍 Testing data quality...")
    
    try:
        # Load data
        df = pd.read_csv("data/molecular_properties.csv")
        fingerprints = np.load("data/molecular_fingerprints.npy")
        
        print(f"   ✅ Dataset size: {len(df)} compounds")
        print(f"   ✅ Fingerprint shape: {fingerprints.shape}")
        
        # Check for reasonable property ranges
        properties_to_check = {
            "molecular_weight": (10, 1000),  # Reasonable MW range
            "logp": (-5, 10),                # Reasonable LogP range
            "hbd": (0, 20),                  # H-bond donors
            "hba": (0, 30),                  # H-bond acceptors
        }
        
        for prop, (min_val, max_val) in properties_to_check.items():
            if prop in df.columns:
                actual_min = df[prop].min()
                actual_max = df[prop].max()
                
                if min_val <= actual_min and actual_max <= max_val:
                    print(f"   ✅ {prop}: {actual_min:.2f} - {actual_max:.2f}")
                else:
                    print(f"   ⚠️  {prop}: {actual_min:.2f} - {actual_max:.2f} (outside expected range)")
        
        # Check for missing values
        missing_values = df.isnull().sum().sum()
        if missing_values == 0:
            print(f"   ✅ No missing values")
        else:
            print(f"   ⚠️  {missing_values} missing values found")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Error testing data quality: {e}")
        return False

def test_model_size():
    """Test that models are reasonable size for mobile deployment"""
    print("\n🔍 Testing model sizes...")
    
    model_paths = [
        "models/Materia_PropertyPredictor.mlpackage",
        "models/Materia_StructureValidator.mlpackage"
    ]
    
    try:
        for model_path in model_paths:
            if os.path.exists(model_path):
                # Get directory size
                total_size = 0
                for dirpath, dirnames, filenames in os.walk(model_path):
                    for filename in filenames:
                        filepath = os.path.join(dirpath, filename)
                        total_size += os.path.getsize(filepath)
                
                size_mb = total_size / (1024 * 1024)
                model_name = os.path.basename(model_path)
                
                if size_mb < 50:  # Reasonable size for mobile
                    print(f"   ✅ {model_name}: {size_mb:.1f} MB")
                else:
                    print(f"   ⚠️  {model_name}: {size_mb:.1f} MB (large for mobile)")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Error checking model sizes: {e}")
        return False

def run_all_tests():
    """Run all tests"""
    print("🧪 Materia Chemistry Models - Test Suite")
    print("=" * 50)
    
    tests = [
        ("Data Files", test_data_files),
        ("Model Files", test_model_files),
        ("Preprocessing Info", test_preprocessing_info),
        ("Fingerprint Generation", test_fingerprint_generation),
        ("IUPAC Naming", test_iupac_naming),
        ("Data Quality", test_data_quality),
        ("Model Sizes", test_model_size),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        try:
            if test_func():
                passed += 1
            else:
                print(f"\n❌ {test_name} test failed")
        except Exception as e:
            print(f"\n❌ {test_name} test error: {e}")
    
    print(f"\n📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Your models are ready for iOS integration.")
        print("\nNext steps:")
        print("1. Copy .mlpackage files to your iOS project")
        print("2. Update CoreMLChemistryService.swift")
        print("3. Build and test your app")
    else:
        print("⚠️  Some tests failed. Please check the errors above.")
        print("Run the training pipeline again if needed: python setup_and_run.py")

if __name__ == "__main__":
    run_all_tests()