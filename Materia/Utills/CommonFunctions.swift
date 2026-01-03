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
}
