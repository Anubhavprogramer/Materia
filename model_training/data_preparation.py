#!/usr/bin/env python3
"""
Data Preparation Pipeline for Materia Chemistry Models
Downloads and processes chemical data from public sources
"""

import pandas as pd
import numpy as np
import requests
import gzip
import io
import os
from tqdm import tqdm
from rdkit import Chem
from rdkit.Chem import Descriptors, rdMolDescriptors, Crippen
from rdkit.Chem.rdMolDescriptors import CalcTPSA
import pickle

class ChemicalDataProcessor:
    def __init__(self, data_dir="data"):
        self.data_dir = data_dir
        os.makedirs(data_dir, exist_ok=True)
        
    def download_pubchem_sample(self, max_compounds=50000):
        """Download a sample of PubChem data for training"""
        print("📥 Downloading PubChem sample data...")
        
        # For demo purposes, we'll create a curated dataset of common compounds
        # In production, you'd download from PubChem FTP
        sample_compounds = [
            # Alkanes
            ("C", "Methane"),
            ("CC", "Ethane"), 
            ("CCC", "Propane"),
            ("CCCC", "Butane"),
            ("CCCCC", "Pentane"),
            ("CCCCCC", "Hexane"),
            ("CCCCCCC", "Heptane"),
            ("CCCCCCCC", "Octane"),
            
            # Alcohols
            ("CO", "Methanol"),
            ("CCO", "Ethanol"),
            ("CCCO", "Propanol"),
            ("CCCCO", "Butanol"),
            ("CCCCCO", "Pentanol"),
            
            # Carboxylic acids
            ("C(=O)O", "Formic acid"),
            ("CC(=O)O", "Acetic acid"),
            ("CCC(=O)O", "Propanoic acid"),
            ("CCCC(=O)O", "Butanoic acid"),
            
            # Aldehydes
            ("C=O", "Formaldehyde"),
            ("CC=O", "Acetaldehyde"),
            ("CCC=O", "Propanal"),
            ("CCCC=O", "Butanal"),
            
            # Ketones
            ("CC(=O)C", "Acetone"),
            ("CC(=O)CC", "Butanone"),
            ("CC(=O)CCC", "Pentanone"),
            
            # Amines
            ("CN", "Methylamine"),
            ("CCN", "Ethylamine"),
            ("CCCN", "Propylamine"),
            
            # Halogenated compounds
            ("CCl", "Chloroethane"),
            ("CBr", "Bromomethane"),
            ("CF", "Fluoromethane"),
            ("CI", "Iodomethane"),
            
            # Aromatic compounds
            ("c1ccccc1", "Benzene"),
            ("Cc1ccccc1", "Toluene"),
            ("c1ccc(cc1)O", "Phenol"),
            ("c1ccc(cc1)N", "Aniline"),
            
            # Ethers
            ("COC", "Dimethyl ether"),
            ("CCOC", "Ethyl methyl ether"),
            ("CCOCC", "Diethyl ether"),
            
            # Esters
            ("CC(=O)OC", "Methyl acetate"),
            ("CC(=O)OCC", "Ethyl acetate"),
            ("CCC(=O)OC", "Methyl propanoate"),
            
            # Nitriles
            ("CC#N", "Acetonitrile"),
            ("CCC#N", "Propanenitrile"),
            
            # Thiols
            ("CS", "Methanethiol"),
            ("CCS", "Ethanethiol"),
            
            # Multiple functional groups
            ("CC(C)CO", "Isobutanol"),
            ("CC(C)(C)O", "tert-Butanol"),
            ("CC(O)C(=O)O", "Lactic acid"),
            ("NCCO", "Ethanolamine"),
            ("c1ccc(cc1)C(=O)O", "Benzoic acid"),
            ("c1ccc(cc1)CO", "Benzyl alcohol"),
            
            # Larger molecules
            ("CCCCCCCCCCCCCCCCCC(=O)O", "Stearic acid"),
            ("CC(C)CCCC(C)CCCC(C)CCCC(C)C", "Squalane"),
            ("CCO.CCO", "Ethylene glycol"),
            
            # Drugs and bioactive compounds (simplified)
            ("CC(C)NCC(c1ccc(cc1)O)O", "Isoproterenol"),
            ("CN1CCC[C@H]1c2cccnc2", "Nicotine"),
            ("CC(=O)Oc1ccccc1C(=O)O", "Aspirin"),
            ("CN(C)CCc1c[nH]c2ccc(cc12)O", "Serotonin"),
        ]
        
        # Expand dataset by generating variations
        expanded_compounds = []
        for smiles, name in sample_compounds:
            expanded_compounds.append((smiles, name))
            
            # Generate some structural variations
            mol = Chem.MolFromSmiles(smiles)
            if mol and mol.GetNumAtoms() < 20:  # Only for smaller molecules
                # Try adding methyl groups at different positions
                for i in range(min(3, mol.GetNumAtoms())):
                    try:
                        # This is a simplified approach - in practice you'd use more sophisticated methods
                        modified_smiles = self.add_methyl_variation(smiles)
                        if modified_smiles and modified_smiles != smiles:
                            expanded_compounds.append((modified_smiles, f"Methyl-{name}"))
                    except:
                        continue
        
        # Remove duplicates
        unique_compounds = list(set(expanded_compounds))
        
        print(f"✅ Generated {len(unique_compounds)} unique compounds")
        return unique_compounds[:max_compounds]
    
    def add_methyl_variation(self, smiles):
        """Add simple methyl variations to create more training data"""
        try:
            mol = Chem.MolFromSmiles(smiles)
            if not mol:
                return None
                
            # Simple approach: try to add C to the SMILES string
            variations = [
                smiles + "C",  # Add methyl at end
                "C" + smiles,  # Add methyl at beginning
                smiles.replace("C", "CC", 1),  # Replace first C with CC
            ]
            
            for var in variations:
                test_mol = Chem.MolFromSmiles(var)
                if test_mol and test_mol.GetNumAtoms() <= 30:
                    return var
            return None
        except:
            return None
    
    def calculate_properties(self, compounds):
        """Calculate molecular properties using RDKit"""
        print("🧮 Calculating molecular properties...")
        
        properties_data = []
        valid_compounds = []
        
        for smiles, name in tqdm(compounds, desc="Processing compounds"):
            try:
                mol = Chem.MolFromSmiles(smiles)
                if mol is None:
                    continue
                
                # Calculate properties
                props = {
                    'smiles': smiles,
                    'name': name,
                    'molecular_weight': Descriptors.MolWt(mol),
                    'logp': Crippen.MolLogP(mol),
                    'hbd': Descriptors.NumHDonors(mol),
                    'hba': Descriptors.NumHAcceptors(mol),
                    'tpsa': CalcTPSA(mol),
                    'rotatable_bonds': Descriptors.NumRotatableBonds(mol),
                    'aromatic_rings': Descriptors.NumAromaticRings(mol),
                    'heavy_atoms': mol.GetNumHeavyAtoms(),
                    'formal_charge': Chem.rdmolops.GetFormalCharge(mol),
                    'num_rings': Descriptors.RingCount(mol),
                    'num_heteroatoms': Descriptors.NumHeteroatoms(mol),
                    'molar_refractivity': Crippen.MolMR(mol),
                }
                
                # Add Lipinski's Rule of Five compliance
                props['lipinski_violations'] = sum([
                    props['molecular_weight'] > 500,
                    props['logp'] > 5,
                    props['hbd'] > 5,
                    props['hba'] > 10
                ])
                
                # Add drug-likeness indicators
                props['is_drug_like'] = props['lipinski_violations'] <= 1
                props['is_large_molecule'] = props['molecular_weight'] > 500
                props['is_lipophilic'] = props['logp'] > 3
                props['has_high_hbond_count'] = (props['hbd'] + props['hba']) > 10
                
                properties_data.append(props)
                valid_compounds.append((smiles, name))
                
            except Exception as e:
                print(f"⚠️  Error processing {smiles}: {e}")
                continue
        
        print(f"✅ Successfully processed {len(properties_data)} compounds")
        return pd.DataFrame(properties_data), valid_compounds
    
    def generate_molecular_fingerprints(self, compounds):
        """Generate ECFP4 molecular fingerprints"""
        print("🔍 Generating molecular fingerprints...")
        
        fingerprints = []
        valid_smiles = []
        
        for smiles, name in tqdm(compounds, desc="Generating fingerprints"):
            try:
                mol = Chem.MolFromSmiles(smiles)
                if mol is None:
                    continue
                
                # Generate ECFP4 fingerprint (Morgan fingerprint with radius 2)
                fp = rdMolDescriptors.GetMorganFingerprintAsBitVect(
                    mol, radius=2, nBits=2048
                )
                
                # Convert to numpy array
                fp_array = np.array(fp, dtype=np.float32)
                fingerprints.append(fp_array)
                valid_smiles.append(smiles)
                
            except Exception as e:
                print(f"⚠️  Error generating fingerprint for {smiles}: {e}")
                continue
        
        fingerprints_array = np.array(fingerprints)
        print(f"✅ Generated fingerprints: {fingerprints_array.shape}")
        
        return fingerprints_array, valid_smiles
    
    def save_processed_data(self, properties_df, fingerprints, smiles_list):
        """Save processed data for model training"""
        print("💾 Saving processed data...")
        
        # Save properties DataFrame
        properties_df.to_csv(os.path.join(self.data_dir, "molecular_properties.csv"), index=False)
        
        # Save fingerprints
        np.save(os.path.join(self.data_dir, "molecular_fingerprints.npy"), fingerprints)
        
        # Save SMILES list
        with open(os.path.join(self.data_dir, "smiles_list.pkl"), "wb") as f:
            pickle.dump(smiles_list, f)
        
        print("✅ Data saved successfully!")
        
        # Print summary statistics
        print("\n📊 Dataset Summary:")
        print(f"Total compounds: {len(properties_df)}")
        print(f"Fingerprint dimensions: {fingerprints.shape}")
        
        if len(properties_df) > 0:
            print("\nProperty ranges:")
            numeric_cols = ['molecular_weight', 'logp', 'hbd', 'hba', 'tpsa', 'rotatable_bonds']
            for col in numeric_cols:
                if col in properties_df.columns:
                    print(f"  {col}: {properties_df[col].min():.2f} - {properties_df[col].max():.2f}")
        else:
            print("⚠️  No valid compounds processed!")
        
        return properties_df, fingerprints, smiles_list

def main():
    """Main data preparation pipeline"""
    print("🧪 Starting Materia Chemistry Data Preparation Pipeline")
    print("=" * 60)
    
    processor = ChemicalDataProcessor()
    
    # Step 1: Download/generate compound data
    compounds = processor.download_pubchem_sample(max_compounds=1000)
    
    # Step 2: Calculate molecular properties
    properties_df, valid_compounds = processor.calculate_properties(compounds)
    
    # Step 3: Generate molecular fingerprints
    fingerprints, smiles_list = processor.generate_molecular_fingerprints(valid_compounds)
    
    # Step 4: Save processed data
    processor.save_processed_data(properties_df, fingerprints, smiles_list)
    
    print("\n🎉 Data preparation complete!")
    print("Next step: Run 'python model_training.py' to train the models")

if __name__ == "__main__":
    main()