#!/usr/bin/env python3
"""
Model Training Pipeline for Materia Chemistry Models
Trains CoreML models for molecular property prediction
"""

import pandas as pd
import numpy as np
import os
import pickle
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_absolute_error, r2_score
import tensorflow as tf
from tensorflow import keras
import coremltools as ct
import matplotlib.pyplot as plt
import seaborn as sns

class ChemistryModelTrainer:
    def __init__(self, data_dir="data", models_dir="models"):
        self.data_dir = data_dir
        self.models_dir = models_dir
        os.makedirs(models_dir, exist_ok=True)
        
    def load_data(self):
        """Load processed data"""
        print("📂 Loading processed data...")
        
        # Load properties
        properties_df = pd.read_csv(os.path.join(self.data_dir, "molecular_properties.csv"))
        
        # Load fingerprints
        fingerprints = np.load(os.path.join(self.data_dir, "molecular_fingerprints.npy"))
        
        # Load SMILES
        with open(os.path.join(self.data_dir, "smiles_list.pkl"), "rb") as f:
            smiles_list = pickle.load(f)
        
        print(f"✅ Loaded {len(properties_df)} compounds")
        return properties_df, fingerprints, smiles_list
    
    def prepare_training_data(self, properties_df, fingerprints):
        """Prepare data for training"""
        print("🔧 Preparing training data...")
        
        # Define target properties for prediction
        target_properties = [
            'molecular_weight',
            'logp', 
            'hbd',
            'hba',
            'tpsa',
            'rotatable_bonds',
            'aromatic_rings',
            'heavy_atoms'
        ]
        
        # Extract features (fingerprints) and targets (properties)
        X = fingerprints
        y = properties_df[target_properties].values
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        
        # Scale targets for better training
        self.target_scaler = StandardScaler()
        y_train_scaled = self.target_scaler.fit_transform(y_train)
        y_test_scaled = self.target_scaler.transform(y_test)
        
        print(f"✅ Training set: {X_train.shape[0]} samples")
        print(f"✅ Test set: {X_test.shape[0]} samples")
        print(f"✅ Features: {X_train.shape[1]} (molecular fingerprint bits)")
        print(f"✅ Targets: {len(target_properties)} properties")
        
        return (X_train, X_test, y_train_scaled, y_test_scaled, 
                y_train, y_test, target_properties)
    
    def build_property_predictor_model(self, input_dim, output_dim):
        """Build neural network for property prediction"""
        print("🏗️  Building property predictor model...")
        
        model = keras.Sequential([
            keras.layers.Dense(512, activation='relu', input_shape=(input_dim,)),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.3),
            
            keras.layers.Dense(256, activation='relu'),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.3),
            
            keras.layers.Dense(128, activation='relu'),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.2),
            
            keras.layers.Dense(64, activation='relu'),
            keras.layers.Dropout(0.1),
            
            keras.layers.Dense(output_dim, activation='linear')
        ])
        
        # Use custom loss function that handles different property scales
        model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=0.001),
            loss='mse',
            metrics=['mae']
        )
        
        print(f"✅ Model built with {model.count_params():,} parameters")
        return model
    
    def train_property_predictor(self, X_train, X_test, y_train_scaled, y_test_scaled):
        """Train the property prediction model"""
        print("🚀 Training property predictor...")
        
        model = self.build_property_predictor_model(
            input_dim=X_train.shape[1], 
            output_dim=y_train_scaled.shape[1]
        )
        
        # Callbacks for training
        callbacks = [
            keras.callbacks.EarlyStopping(
                patience=15, 
                restore_best_weights=True,
                monitor='val_loss'
            ),
            keras.callbacks.ReduceLROnPlateau(
                patience=8, 
                factor=0.5,
                monitor='val_loss'
            ),
            keras.callbacks.ModelCheckpoint(
                os.path.join(self.models_dir, "best_property_model.h5"),
                save_best_only=True,
                monitor='val_loss'
            )
        ]
        
        # Train model
        history = model.fit(
            X_train, y_train_scaled,
            validation_data=(X_test, y_test_scaled),
            epochs=100,
            batch_size=32,
            callbacks=callbacks,
            verbose=1
        )
        
        print("✅ Training completed!")
        return model, history
    
    def evaluate_model(self, model, X_test, y_test_scaled, y_test, target_properties):
        """Evaluate model performance"""
        print("📊 Evaluating model performance...")
        
        # Make predictions
        y_pred_scaled = model.predict(X_test)
        y_pred = self.target_scaler.inverse_transform(y_pred_scaled)
        
        # Calculate metrics for each property
        results = {}
        for i, prop in enumerate(target_properties):
            mae = mean_absolute_error(y_test[:, i], y_pred[:, i])
            r2 = r2_score(y_test[:, i], y_pred[:, i])
            results[prop] = {'mae': mae, 'r2': r2}
            print(f"  {prop}: MAE={mae:.3f}, R²={r2:.3f}")
        
        # Overall metrics
        overall_mae = mean_absolute_error(y_test, y_pred)
        overall_r2 = r2_score(y_test, y_pred)
        
        print(f"\n📈 Overall Performance:")
        print(f"  Mean Absolute Error: {overall_mae:.3f}")
        print(f"  R² Score: {overall_r2:.3f}")
        
        return results, y_pred
    
    def build_structure_validator_model(self, input_dim):
        """Build binary classifier for structure validation"""
        print("🏗️  Building structure validator model...")
        
        model = keras.Sequential([
            keras.layers.Dense(256, activation='relu', input_shape=(input_dim,)),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.3),
            
            keras.layers.Dense(128, activation='relu'),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.3),
            
            keras.layers.Dense(64, activation='relu'),
            keras.layers.Dropout(0.2),
            
            keras.layers.Dense(1, activation='sigmoid')
        ])
        
        model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=0.001),
            loss='binary_crossentropy',
            metrics=['accuracy']
        )
        
        print(f"✅ Validator model built with {model.count_params():,} parameters")
        return model
    
    def create_validation_dataset(self, fingerprints, properties_df):
        """Create dataset for structure validation training"""
        print("🔧 Creating structure validation dataset...")
        
        # All our compounds are valid (they came from RDKit parsing)
        valid_fingerprints = fingerprints
        valid_labels = np.ones(len(fingerprints))
        
        # Generate invalid structures by corrupting fingerprints
        invalid_fingerprints = []
        for fp in fingerprints[:len(fingerprints)//2]:  # Generate half as many invalid
            # Corrupt fingerprint by flipping random bits
            corrupted_fp = fp.copy()
            num_flips = np.random.randint(50, 200)  # Flip 50-200 bits
            flip_indices = np.random.choice(len(fp), num_flips, replace=False)
            corrupted_fp[flip_indices] = 1 - corrupted_fp[flip_indices]
            invalid_fingerprints.append(corrupted_fp)
        
        invalid_fingerprints = np.array(invalid_fingerprints)
        invalid_labels = np.zeros(len(invalid_fingerprints))
        
        # Combine datasets
        X_val = np.vstack([valid_fingerprints, invalid_fingerprints])
        y_val = np.hstack([valid_labels, invalid_labels])
        
        print(f"✅ Validation dataset: {len(valid_labels)} valid + {len(invalid_labels)} invalid")
        return X_val, y_val
    
    def train_structure_validator(self, fingerprints, properties_df):
        """Train structure validation model"""
        print("🚀 Training structure validator...")
        
        # Create validation dataset
        X_val, y_val = self.create_validation_dataset(fingerprints, properties_df)
        
        # Split data
        X_train_val, X_test_val, y_train_val, y_test_val = train_test_split(
            X_val, y_val, test_size=0.2, random_state=42
        )
        
        # Build and train model
        validator_model = self.build_structure_validator_model(X_train_val.shape[1])
        
        history_val = validator_model.fit(
            X_train_val, y_train_val,
            validation_data=(X_test_val, y_test_val),
            epochs=50,
            batch_size=32,
            callbacks=[
                keras.callbacks.EarlyStopping(patience=10, restore_best_weights=True),
                keras.callbacks.ReduceLROnPlateau(patience=5, factor=0.5)
            ],
            verbose=1
        )
        
        # Evaluate
        val_loss, val_acc = validator_model.evaluate(X_test_val, y_test_val, verbose=0)
        print(f"✅ Validator accuracy: {val_acc:.3f}")
        
        return validator_model, history_val
    
    def convert_to_coreml(self, tf_model, model_name, input_description, output_description, target_properties=None):
        """Convert TensorFlow model to CoreML"""
        print(f"🔄 Converting {model_name} to CoreML...")
        
        try:
            # Convert to CoreML with explicit source specification
            coreml_model = ct.convert(
                tf_model,
                source="tensorflow",
                inputs=[ct.TensorType(shape=(1, 2048), name="molecular_fingerprint")],
                minimum_deployment_target=ct.target.iOS15
            )
            
            # Add metadata
            coreml_model.short_description = f"Materia Chemistry {model_name}"
            coreml_model.input_description["molecular_fingerprint"] = input_description
            
            if target_properties:
                # Add output descriptions for property predictor
                output_names = list(coreml_model.output_description.keys())
                if len(output_names) > 0:
                    main_output = output_names[0]
                    coreml_model.output_description[main_output] = f"Predicted properties: {', '.join(target_properties)}"
            else:
                # For structure validator
                output_names = list(coreml_model.output_description.keys())
                if len(output_names) > 0:
                    main_output = output_names[0]
                    coreml_model.output_description[main_output] = output_description
            
            # Save model
            model_path = os.path.join(self.models_dir, f"Materia_{model_name}.mlpackage")
            coreml_model.save(model_path)
            
            print(f"✅ CoreML model saved: {model_path}")
            return coreml_model, model_path
            
        except Exception as e:
            print(f"⚠️  CoreML conversion failed: {e}")
            print(f"   Saving TensorFlow model instead...")
            
            # Save as TensorFlow model if CoreML conversion fails
            tf_model_path = os.path.join(self.models_dir, f"Materia_{model_name}.h5")
            tf_model.save(tf_model_path)
            print(f"✅ TensorFlow model saved: {tf_model_path}")
            
            return None, tf_model_path
    
    def save_preprocessing_info(self, target_scaler, target_properties):
        """Save preprocessing information for iOS integration"""
        preprocessing_info = {
            'target_properties': target_properties,
            'scaler_mean': target_scaler.mean_.tolist(),
            'scaler_scale': target_scaler.scale_.tolist(),
            'fingerprint_size': 2048,
            'fingerprint_type': 'ECFP4'
        }
        
        with open(os.path.join(self.models_dir, "preprocessing_info.pkl"), "wb") as f:
            pickle.dump(preprocessing_info, f)
        
        # Also save as JSON for easier iOS integration
        import json
        with open(os.path.join(self.models_dir, "preprocessing_info.json"), "w") as f:
            json.dump(preprocessing_info, f, indent=2)
        
        print("✅ Preprocessing info saved")

def main():
    """Main training pipeline"""
    print("🧪 Starting Materia Chemistry Model Training Pipeline")
    print("=" * 60)
    
    trainer = ChemistryModelTrainer()
    
    # Load data
    properties_df, fingerprints, smiles_list = trainer.load_data()
    
    # Prepare training data
    (X_train, X_test, y_train_scaled, y_test_scaled, 
     y_train, y_test, target_properties) = trainer.prepare_training_data(properties_df, fingerprints)
    
    # Train property predictor
    property_model, history = trainer.train_property_predictor(
        X_train, X_test, y_train_scaled, y_test_scaled
    )
    
    # Evaluate property predictor
    results, y_pred = trainer.evaluate_model(
        property_model, X_test, y_test_scaled, y_test, target_properties
    )
    
    # Train structure validator
    validator_model, history_val = trainer.train_structure_validator(fingerprints, properties_df)
    
    # Convert models to CoreML
    property_coreml, property_path = trainer.convert_to_coreml(
        property_model,
        "PropertyPredictor",
        "2048-bit ECFP4 molecular fingerprint",
        "Predicted molecular properties",
        target_properties
    )
    
    validator_coreml, validator_path = trainer.convert_to_coreml(
        validator_model,
        "StructureValidator", 
        "2048-bit ECFP4 molecular fingerprint",
        "Structure validity probability (0-1)"
    )
    
    # Save preprocessing information
    trainer.save_preprocessing_info(trainer.target_scaler, target_properties)
    
    print("\n🎉 Model training complete!")
    print(f"📁 Models saved in: {trainer.models_dir}/")
    print(f"   - Materia_PropertyPredictor.mlpackage")
    print(f"   - Materia_StructureValidator.mlpackage")
    print(f"   - preprocessing_info.json")
    print("\nNext step: Copy .mlpackage files to your iOS project!")

if __name__ == "__main__":
    main()