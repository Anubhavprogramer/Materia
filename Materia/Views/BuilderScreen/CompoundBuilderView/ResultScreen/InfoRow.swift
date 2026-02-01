//
//  InfoRow.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//
import SwiftUI

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.subheadline, design: title == "Structure Notation" ? .monospaced : .default))
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}
