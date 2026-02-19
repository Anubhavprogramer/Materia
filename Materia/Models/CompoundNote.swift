//
//  CompoundNote.swift
//  Materia
//
//  Created by Anubhav Dubey on 17/02/26.
//

import Foundation
import SwiftUI

struct CompoundNote: Identifiable, Codable {
    let id: UUID
    let compoundId: UUID
    var content: String
    let createdAt: Date
    var updatedAt: Date

    init(compoundId: UUID, content: String) {
        self.id = UUID()
        self.compoundId = compoundId
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    mutating func update(content: String) {
        self.content = content
        self.updatedAt = Date()
    }
}