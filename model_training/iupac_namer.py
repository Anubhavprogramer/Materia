#!/usr/bin/env python3
"""
Rule-based IUPAC Naming Engine for Materia Chemistry App
Generates systematic IUPAC names following official nomenclature rules
"""

from dataclasses import dataclass
from typing import List, Dict, Tuple, Optional
import json
import os

@dataclass
class FunctionalGroupInfo:
    name: str
    suffix: str
    prefix: str
    priority: int
    requires_number: bool = True

class IUPACNamer:
    """Rule-based IUPAC naming engine"""
    
    def __init__(self):
        self.setup_nomenclature_rules()
    
    def setup_nomenclature_rules(self):
        """Initialize IUPAC nomenclature rules and data"""
        
        # Base alkane names
        self.alkane_names = [
            "", "meth", "eth", "prop", "but", "pent", 
            "hex", "hept", "oct", "non", "dec",
            "undec", "dodec", "tridec", "tetradec", "pentadec",
            "hexadec", "heptadec", "octadec", "nonadec", "icos"
        ]
        
        # Functional group priorities (higher number = higher priority)
        self.functional_groups = {
            "carboxylic_acid": FunctionalGroupInfo("carboxylic acid", "oic acid", "carboxy", 10),
            "ester": FunctionalGroupInfo("ester", "oate", "alkoxycarbonyl", 9),
            "amide": FunctionalGroupInfo("amide", "amide", "carbamoyl", 8),
            "nitrile": FunctionalGroupInfo("nitrile", "nitrile", "cyano", 7),
            "aldehyde": FunctionalGroupInfo("aldehyde", "al", "formyl", 6),
            "ketone": FunctionalGroupInfo("ketone", "one", "oxo", 5),
            "alcohol": FunctionalGroupInfo("alcohol", "ol", "hydroxy", 4),
            "thiol": FunctionalGroupInfo("thiol", "thiol", "mercapto", 3),
            "amine": FunctionalGroupInfo("amine", "amine", "amino", 2),
            "ether": FunctionalGroupInfo("ether", "", "alkoxy", 1),
            "halogen": FunctionalGroupInfo("halogen", "", "halo", 1),
        }
        
        # Halogen names
        self.halogen_names = {
            "F": "fluoro",
            "Cl": "chloro", 
            "Br": "bromo",
            "I": "iodo"
        }
        
        # Number prefixes for multiple groups
        self.multiplicity_prefixes = {
            2: "di", 3: "tri", 4: "tetra", 5: "penta",
            6: "hexa", 7: "hepta", 8: "octa", 9: "nona", 10: "deca"
        }
    
    def generate_iupac_name(self, structure) -> str:
        """Generate IUPAC name from ChemicalStructure"""
        try:
            # Step 1: Identify the longest carbon chain
            chain_length = structure.carbonChainLength
            
            # Step 2: Analyze functional groups
            functional_groups = self.analyze_functional_groups(structure)
            
            # Step 3: Determine principal functional group
            principal_group = self.get_principal_functional_group(functional_groups)
            
            # Step 4: Number the carbon chain
            numbering = self.number_carbon_chain(structure, principal_group)
            
            # Step 5: Construct the name
            name = self.construct_iupac_name(
                chain_length, functional_groups, principal_group, numbering, structure
            )
            
            return name
            
        except Exception as e:
            print(f"Error generating IUPAC name: {e}")
            return self.generate_fallback_name(structure)
    
    def analyze_functional_groups(self, structure) -> Dict[str, List[int]]:
        """Analyze functional groups and their positions"""
        groups = {}
        
        for attachment in structure.functionalGroups:
            group_type = self.classify_functional_group(attachment.group)
            position = attachment.carbonPosition
            
            if group_type not in groups:
                groups[group_type] = []
            groups[group_type].append(position)
        
        # Sort positions for each group type
        for group_type in groups:
            groups[group_type].sort()
        
        return groups
    
    def classify_functional_group(self, group) -> str:
        """Map ChemicalStructure functional groups to IUPAC categories"""
        mapping = {
            "alcohol": "alcohol",
            "carboxylicAcid": "carboxylic_acid", 
            "aldehyde": "aldehyde",
            "ketone": "ketone",
            "amine": "amine",
            "thiol": "thiol",
            "nitrile": "nitrile",
            "fluorine": "halogen",
            "chlorine": "halogen",
            "bromine": "halogen",
            "iodine": "halogen",
        }
        
        group_str = str(group).split('.')[-1] if hasattr(group, '__class__') else str(group)
        return mapping.get(group_str, "unknown")
    
    def get_principal_functional_group(self, functional_groups: Dict[str, List[int]]) -> Optional[str]:
        """Determine the principal functional group (highest priority)"""
        if not functional_groups:
            return None
        
        highest_priority = 0
        principal_group = None
        
        for group_type in functional_groups:
            if group_type in self.functional_groups:
                priority = self.functional_groups[group_type].priority
                if priority > highest_priority:
                    highest_priority = priority
                    principal_group = group_type
        
        return principal_group
    
    def number_carbon_chain(self, structure, principal_group: Optional[str]) -> List[int]:
        """Number the carbon chain to give principal group lowest numbers"""
        chain_length = structure.carbonChainLength
        
        if not principal_group:
            # No principal group, use standard numbering
            return list(range(1, chain_length + 1))
        
        # For now, use simple numbering - in a full implementation,
        # this would consider the actual molecular structure
        return list(range(1, chain_length + 1))
    
    def construct_iupac_name(self, chain_length: int, functional_groups: Dict[str, List[int]], 
                           principal_group: Optional[str], numbering: List[int], structure) -> str:
        """Construct the final IUPAC name"""
        
        # Get base name
        base_name = self.get_base_name(chain_length)
        
        # Handle different cases
        if not functional_groups:
            # Simple alkane
            return base_name + "ane"
        
        # Build name components
        prefixes = []
        suffix = "ane"
        
        # Process functional groups
        for group_type, positions in functional_groups.items():
            if group_type == principal_group:
                # Principal group becomes suffix
                suffix = self.get_suffix_for_group(group_type, positions, chain_length)
            else:
                # Other groups become prefixes
                prefix = self.get_prefix_for_group(group_type, positions)
                if prefix:
                    prefixes.append(prefix)
        
        # Handle multiple bonds (double/triple)
        bond_info = self.analyze_bonds(structure)
        if bond_info:
            prefixes.extend(bond_info)
            # Modify suffix for unsaturated compounds
            if suffix == "ane":
                if "en" in bond_info[0]:  # Double bonds
                    suffix = "ene"
                elif "yn" in bond_info[0]:  # Triple bonds
                    suffix = "yne"
        
        # Combine components
        prefix_part = "".join(sorted(prefixes)) if prefixes else ""
        name = prefix_part + base_name + suffix
        
        return name
    
    def get_base_name(self, chain_length: int) -> str:
        """Get the base alkane name for the carbon chain"""
        if chain_length <= len(self.alkane_names) - 1:
            return self.alkane_names[chain_length]
        else:
            return f"{chain_length}-carbon"
    
    def get_suffix_for_group(self, group_type: str, positions: List[int], chain_length: int) -> str:
        """Get suffix for principal functional group"""
        if group_type not in self.functional_groups:
            return "ane"
        
        group_info = self.functional_groups[group_type]
        suffix = group_info.suffix
        
        # Handle position numbers for suffix
        if group_info.requires_number and len(positions) == 1 and chain_length > 2:
            # Add position number for single group
            if group_type in ["alcohol", "ketone", "thiol"]:
                suffix = f"{positions[0]}-{suffix}"
        elif len(positions) > 1:
            # Multiple groups
            multiplicity = self.multiplicity_prefixes.get(len(positions), str(len(positions)))
            position_str = ",".join(map(str, positions))
            suffix = f"{position_str}-{multiplicity}{suffix}"
        
        return suffix
    
    def get_prefix_for_group(self, group_type: str, positions: List[int]) -> str:
        """Get prefix for non-principal functional groups"""
        if group_type not in self.functional_groups:
            return ""
        
        group_info = self.functional_groups[group_type]
        prefix = group_info.prefix
        
        # Handle halogens specially
        if group_type == "halogen":
            # This would need more sophisticated logic to determine which halogen
            prefix = "halo"  # Simplified
        
        # Handle multiplicity
        if len(positions) > 1:
            multiplicity = self.multiplicity_prefixes.get(len(positions), str(len(positions)))
            prefix = f"{multiplicity}{prefix}"
        
        # Add position numbers
        position_str = ",".join(map(str, positions))
        return f"{position_str}-{prefix}"
    
    def analyze_bonds(self, structure) -> List[str]:
        """Analyze double and triple bonds"""
        bond_info = []
        
        double_bonds = [b for b in structure.bonds if str(b.type).split('.')[-1] == "double"]
        triple_bonds = [b for b in structure.bonds if str(b.type).split('.')[-1] == "triple"]
        
        if double_bonds:
            positions = [min(b.fromCarbon, b.toCarbon) for b in double_bonds]
            positions.sort()
            if len(positions) == 1:
                bond_info.append(f"{positions[0]}-en")
            else:
                multiplicity = self.multiplicity_prefixes.get(len(positions), str(len(positions)))
                position_str = ",".join(map(str, positions))
                bond_info.append(f"{position_str}-{multiplicity}en")
        
        if triple_bonds:
            positions = [min(b.fromCarbon, b.toCarbon) for b in triple_bonds]
            positions.sort()
            if len(positions) == 1:
                bond_info.append(f"{positions[0]}-yn")
            else:
                multiplicity = self.multiplicity_prefixes.get(len(positions), str(len(positions)))
                position_str = ",".join(map(str, positions))
                bond_info.append(f"{position_str}-{multiplicity}yn")
        
        return bond_info
    
    def generate_fallback_name(self, structure) -> str:
        """Generate a fallback name when systematic naming fails"""
        chain_length = structure.carbonChainLength
        base_name = self.get_base_name(chain_length)
        
        # Count functional groups
        group_count = len(structure.functionalGroups)
        
        if group_count == 0:
            return base_name + "ane"
        elif any(str(g.group).split('.')[-1] == "alcohol" for g in structure.functionalGroups):
            return base_name + "anol"
        elif any(str(g.group).split('.')[-1] == "carboxylicAcid" for g in structure.functionalGroups):
            return base_name + "anoic acid"
        elif any(str(g.group).split('.')[-1] == "aldehyde" for g in structure.functionalGroups):
            return base_name + "anal"
        elif any(str(g.group).split('.')[-1] == "ketone" for g in structure.functionalGroups):
            return base_name + "anone"
        else:
            return f"{base_name}ane derivative"
    
    def get_name_components(self) -> List[str]:
        """Get the components used in the last naming operation"""
        # This would store components from the last naming operation
        # For now, return common components
        return ["alkane", "alcohol", "carboxylic acid", "aldehyde", "ketone"]
    
    def save_nomenclature_rules(self, filepath: str):
        """Save nomenclature rules to JSON file for iOS integration"""
        rules_data = {
            "alkane_names": self.alkane_names,
            "functional_groups": {
                name: {
                    "name": info.name,
                    "suffix": info.suffix,
                    "prefix": info.prefix,
                    "priority": info.priority,
                    "requires_number": info.requires_number
                }
                for name, info in self.functional_groups.items()
            },
            "halogen_names": self.halogen_names,
            "multiplicity_prefixes": self.multiplicity_prefixes
        }
        
        with open(filepath, 'w') as f:
            json.dump(rules_data, f, indent=2)
        
        print(f"✅ IUPAC nomenclature rules saved to {filepath}")

def main():
    """Test the IUPAC naming engine"""
    print("🧪 Testing IUPAC Naming Engine")
    print("=" * 40)
    
    # This would normally import from your iOS project structure
    # For testing, we'll create a mock structure
    class MockFunctionalGroup:
        def __init__(self, group_type):
            self.group = group_type
    
    class MockAttachment:
        def __init__(self, position, group_type):
            self.carbonPosition = position
            self.group = MockFunctionalGroup(group_type)
    
    class MockBond:
        def __init__(self, from_c, to_c, bond_type):
            self.fromCarbon = from_c
            self.toCarbon = to_c
            self.type = MockFunctionalGroup(bond_type)
    
    class MockStructure:
        def __init__(self, chain_length):
            self.carbonChainLength = chain_length
            self.functionalGroups = []
            self.bonds = []
    
    # Initialize namer
    namer = IUPACNamer()
    
    # Test cases
    test_cases = [
        # Simple alkanes
        (MockStructure(1), "methane"),
        (MockStructure(2), "ethane"),
        (MockStructure(3), "propane"),
        (MockStructure(4), "butane"),
        
        # Alcohols
        (MockStructure(1), "methanol"),  # Will add OH
        (MockStructure(2), "ethanol"),   # Will add OH
        
        # Carboxylic acids
        (MockStructure(1), "methanoic acid"),  # Will add COOH
        (MockStructure(2), "ethanoic acid"),   # Will add COOH
    ]
    
    # Add functional groups to test structures
    test_cases[4][0].functionalGroups.append(MockAttachment(1, "alcohol"))
    test_cases[5][0].functionalGroups.append(MockAttachment(1, "alcohol"))
    test_cases[6][0].functionalGroups.append(MockAttachment(1, "carboxylicAcid"))
    test_cases[7][0].functionalGroups.append(MockAttachment(1, "carboxylicAcid"))
    
    # Test naming
    for structure, expected in test_cases:
        result = namer.generate_iupac_name(structure)
        print(f"Chain length {structure.carbonChainLength}: {result}")
    
    # Save rules for iOS integration
    namer.save_nomenclature_rules("models/iupac_rules.json")
    
    print("\n✅ IUPAC naming engine test complete!")

if __name__ == "__main__":
    main()