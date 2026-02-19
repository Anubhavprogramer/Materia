//
//  BondView.swift
//  Materia
//
//  Created by Anubhav Dubey on 01/02/26.
//

import SwiftUI

struct BondView: View {
    let from: CGPoint
    let to: CGPoint
    let type: BondType
    
    var body: some View {
        ZStack {
            switch type {
            case .single:
                Path { path in
                    path.move(to: from)
                    path.addLine(to: to)
                }
                .stroke(Color.black, lineWidth: 2)
                
            case .double:
                Path { path in
                    let offset: CGFloat = 3
                    path.move(to: CGPoint(x: from.x, y: from.y - offset))
                    path.addLine(to: CGPoint(x: to.x, y: to.y - offset))
                    path.move(to: CGPoint(x: from.x, y: from.y + offset))
                    path.addLine(to: CGPoint(x: to.x, y: to.y + offset))
                }
                .stroke(Color.black, lineWidth: 2)
                
            case .triple:
                Path { path in
                    let offset: CGFloat = 4
                    path.move(to: from)
                    path.addLine(to: to)
                    path.move(to: CGPoint(x: from.x, y: from.y - offset))
                    path.addLine(to: CGPoint(x: to.x, y: to.y - offset))
                    path.move(to: CGPoint(x: from.x, y: from.y + offset))
                    path.addLine(to: CGPoint(x: to.x, y: to.y + offset))
                }
                .stroke(Color.black, lineWidth: 2)
            }
        }
    }
}
