//
//  Model3DUserGuide.swift
//  Materia
//
//  On-screen help and instructions for 3D viewer
//

import SwiftUI

struct Model3DUserGuide: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("How to Use 3D View")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Content
                TabView(selection: $currentPage) {
                    // Page 1: Rotation
                    VStack(spacing: 20) {
                        Image(systemName: "hand.draw")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rotation")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "1.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Use 1 finger")
                                        .font(.caption)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("Drag to rotate in all directions")
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .tag(0)
                    
                    // Page 2: Zoom
                    VStack(spacing: 20) {
                        Image(systemName: "hand.pinch")
                            .font(.system(size: 64))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Zoom")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "2.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("Use 2 fingers")
                                        .font(.caption)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("Pinch in/out to zoom")
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .tag(1)
                    
                    // Page 3: Tilt
                    VStack(spacing: 20) {
                        Image(systemName: "rotate.3d")
                            .font(.system(size: 64))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tilt")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "2.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("Use 2 fingers")
                                        .font(.caption)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "rotate.left.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text("Rotate for side view")
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .tag(2)
                    
                    // Page 4: Controls
                    VStack(spacing: 20) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 64))
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Controls")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Auto-rotate for demo")
                                        .font(.caption)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "abc")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("Toggle element labels")
                                        .font(.caption)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("Reset to default view")
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding()
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding()
                
                // Footer buttons
                HStack(spacing: 12) {
                    if currentPage > 0 {
                        Button(action: { withAnimation { currentPage -= 1 } }) {
                            Text("Back")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.gray)
                                .cornerRadius(6)
                        }
                    } else {
                        Spacer()
                    }
                    
                    if currentPage < 3 {
                        Button(action: { withAnimation { currentPage += 1 } }) {
                            Text("Next")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.blue)
                                .cornerRadius(6)
                        }
                    } else {
                        Button(action: { dismiss() }) {
                            Text("Got it!")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.blue)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct Model3DUserGuide_Previews: PreviewProvider {
    static var previews: some View {
        Model3DUserGuide()
    }
}
#endif
