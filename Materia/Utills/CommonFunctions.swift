//
//  CommonFunctions.swift
//  Materia
//
//  Created by Anubhav Dubey on 03/01/26.
//

import Foundation

enum CommonFunctions {
    static func debugPrint(load: String, message: String ){
        print("DEBUG PRINT: \(load.uppercased()) :: \(message)")
    }
    
    static func outPutPrint(load: String, message: String ){
        print("OUTPUT PRINT: \(load.uppercased()) :: \(message)")
    }
    
    static func MessagePrint(load: String, message: String ){
        print("MESSAGE PRINT: \(load.uppercased()) :: \(message)")
    }
    
    static func justPrint(load: String, message: String, thing: Any ){
        print("MESSAGE PRINT: \(load.uppercased()) :: \(message) and has \(thing)")
    }
    
    // MARK: - Notes Feature Debugging
    static func debugNote(action: String, noteId: String, compoundId: String, message: String) {
        print("📝 NOTE DEBUG [\(action)] :: CompoundId: \(compoundId) :: NoteId: \(noteId) :: \(message)")
    }
    
    static func debugNoteAdd(noteId: String, compoundId: String, content: String) {
        print("✅ NOTE ADDED :: CompoundId: \(compoundId) :: NoteId: \(noteId) :: Content: \(content)")
    }
    
    static func debugNoteUpdate(noteId: String, oldContent: String, newContent: String) {
        print("🔄 NOTE UPDATED :: NoteId: \(noteId) :: Old: \(oldContent) → New: \(newContent)")
    }
    
    static func debugNoteDelete(noteId: String, compoundId: String) {
        print("🗑️ NOTE DELETED :: CompoundId: \(compoundId) :: NoteId: \(noteId)")
    }
    
    static func debugNoteSave(compoundId: String, noteCount: Int) {
        print("💾 NOTES SAVED :: CompoundId: \(compoundId) :: Total Notes: \(noteCount)")
    }
    
    static func debugNoteError(action: String, error: String) {
        print("❌ NOTE ERROR [\(action)] :: \(error)")
    }
}
