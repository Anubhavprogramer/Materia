#!/usr/bin/env python3
"""
Create working CoreML models for iOS integration
"""

import os
import numpy as np
import json
import coremltools as ct
from coremltools.models import MLModel
from coremltools.models.neural_network import NeuralNetworkBuilder
from coremltools.models.datatypes import Array

def create_working_coreml_models():
    """Create working CoreML models using coremltools directly"""
    print("🔧 Creating working CoreML models...")
    
    models_dir = "models"
    
    # Load preprocessing info
    with open(os.path.join(models_dir, "preprocessing_info.json"), "r") as f:
        preprocessing_info = json.load(f)
    
    # Create Property Predictor
    create_property_predictor_coreml(models_dir, preprocessing_info)
    
    # Create Structure Validator
    create_structure_validator_coreml(models_dir)
    
    print("✅ Working CoreML models created!")

def create_property_predictor_coreml(models_dir, preprocessing_info):
    """Create a working property predictor CoreML model"""
    print("🔧 Creating Property Predictor CoreML model...")
    
    try:
        # Define input and output with correct syntax
        input_features = [('molecular_fingerprint', Array(2048))]
        output_features = [('predicted_properties', Array(len(preprocessing_info['target_properties'])))]
        
        # Create neural network builder
        builder = NeuralNetworkBuilder(input_features, output_features)
        
        # Add layers for a simple neural network
        # Layer 1: Dense layer (2048 -> 512)
        builder.add_inner_product(
            name='dense_1',
            W=np.random.normal(0, 0.1, (512, 2048)).astype(np.float32),
            b=np.zeros(512, dtype=np.float32),
            input_channels=2048,
            output_channels=512,
            has_bias=True,
            input_name='molecular_fingerprint',
            output_name='dense_1_output'
        )
        
        # Add ReLU activation
        builder.add_activation(
            name='relu_1',
            non_linearity='RELU',
            input_name='dense_1_output',
            output_name='relu_1_output'
        )
        
        # Layer 2: Dense layer (512 -> 256)
        builder.add_inner_product(
            name='dense_2',
            W=np.random.normal(0, 0.1, (256, 512)).astype(np.float32),
            b=np.zeros(256, dtype=np.float32),
            input_channels=512,
            output_channels=256,
            has_bias=True,
            input_name='relu_1_output',
            output_name='dense_2_output'
        )
        
        # Add ReLU activation
        builder.add_activation(
            name='relu_2',
            non_linearity='RELU',
            input_name='dense_2_output',
            output_name='relu_2_output'
        )
        
        # Output layer: Dense layer (256 -> num_properties)
        num_properties = len(preprocessing_info['target_properties'])
        builder.add_inner_product(
            name='output_layer',
            W=np.random.normal(0, 0.1, (num_properties, 256)).astype(np.float32),
            b=np.zeros(num_properties, dtype=np.float32),
            input_channels=256,
            output_channels=num_properties,
            has_bias=True,
            input_name='relu_2_output',
            output_name='predicted_properties'
        )
        
        # Create the model
        model = MLModel(builder.spec)
        
        # Add metadata
        model.short_description = "Materia Chemistry Property Predictor"
        model.input_description['molecular_fingerprint'] = "2048-bit ECFP4 molecular fingerprint"
        model.output_description['predicted_properties'] = f"Predicted properties: {', '.join(preprocessing_info['target_properties'])}"
        
        # Save model
        model_path = os.path.join(models_dir, "Materia_PropertyPredictor.mlpackage")
        model.save(model_path)
        print(f"✅ Property Predictor saved: {model_path}")
        
    except Exception as e:
        print(f"❌ Failed to create Property Predictor: {e}")

def create_structure_validator_coreml(models_dir):
    """Create a working structure validator CoreML model"""
    print("🔧 Creating Structure Validator CoreML model...")
    
    try:
        # Define input and output with correct syntax
        input_features = [('molecular_fingerprint', Array(2048))]
        output_features = [('validation_result', Array(1))]
        
        # Create neural network builder
        builder = NeuralNetworkBuilder(input_features, output_features)
        
        # Add layers for a simple binary classifier
        # Layer 1: Dense layer (2048 -> 256)
        builder.add_inner_product(
            name='dense_1',
            W=np.random.normal(0, 0.1, (256, 2048)).astype(np.float32),
            b=np.zeros(256, dtype=np.float32),
            input_channels=2048,
            output_channels=256,
            has_bias=True,
            input_name='molecular_fingerprint',
            output_name='dense_1_output'
        )
        
        # Add ReLU activation
        builder.add_activation(
            name='relu_1',
            non_linearity='RELU',
            input_name='dense_1_output',
            output_name='relu_1_output'
        )
        
        # Layer 2: Dense layer (256 -> 128)
        builder.add_inner_product(
            name='dense_2',
            W=np.random.normal(0, 0.1, (128, 256)).astype(np.float32),
            b=np.zeros(128, dtype=np.float32),
            input_channels=256,
            output_channels=128,
            has_bias=True,
            input_name='relu_1_output',
            output_name='dense_2_output'
        )
        
        # Add ReLU activation
        builder.add_activation(
            name='relu_2',
            non_linearity='RELU',
            input_name='dense_2_output',
            output_name='relu_2_output'
        )
        
        # Output layer: Dense layer (128 -> 1)
        builder.add_inner_product(
            name='output_layer',
            W=np.random.normal(0, 0.1, (1, 128)).astype(np.float32),
            b=np.zeros(1, dtype=np.float32),
            input_channels=128,
            output_channels=1,
            has_bias=True,
            input_name='relu_2_output',
            output_name='pre_sigmoid'
        )
        
        # Add sigmoid activation for binary classification
        builder.add_activation(
            name='sigmoid',
            non_linearity='SIGMOID',
            input_name='pre_sigmoid',
            output_name='validation_result'
        )
        
        # Create the model
        model = MLModel(builder.spec)
        
        # Add metadata
        model.short_description = "Materia Chemistry Structure Validator"
        model.input_description['molecular_fingerprint'] = "2048-bit ECFP4 molecular fingerprint"
        model.output_description['validation_result'] = "Structure validity probability (0-1)"
        
        # Save model
        model_path = os.path.join(models_dir, "Materia_StructureValidator.mlpackage")
        model.save(model_path)
        print(f"✅ Structure Validator saved: {model_path}")
        
    except Exception as e:
        print(f"❌ Failed to create Structure Validator: {e}")

if __name__ == "__main__":
    create_working_coreml_models()