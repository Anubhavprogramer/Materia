//
//  ToastView.swift
//  Materia
//
//  Reusable toast notification component

import SwiftUI

// MARK: - Toast Type
enum ToastType {
    case success
    case error
    case info
    
    var backgroundColor: Color {
        switch self {
        case .success:
            return Color.green
        case .error:
            return Color.red
        case .info:
            return Color.blue
        }
    }
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

// MARK: - Toast Model
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: Double
    
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: Toast
    @State private var isVisible = true
    var onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: toast.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(toast.message)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(toast.type.backgroundColor)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.9, anchor: .bottom)
            .animation(.easeInOut(duration: AppConstants.toastAnimationDuration), value: isVisible)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                isVisible = false
                DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.toastAnimationDuration) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Toast Container View
struct ToastContainerView<Content: View>: View {
    @State private var currentToast: Toast?
    let content: Content
    
    var body: some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                
                if let toast = currentToast {
                    ToastView(toast: toast) {
                        withAnimation {
                            currentToast = nil
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .onPreferenceChange(ToastPreferenceKey.self) { toast in
            if let toast = toast {
                withAnimation {
                    currentToast = toast
                }
            }
        }
    }
}

// MARK: - Preference Key for Toast
struct ToastPreferenceKey: PreferenceKey {
    static var defaultValue: Toast?
    
    static func reduce(value: inout Toast?, nextValue: () -> Toast?) {
        value = nextValue() ?? value
    }
}

// MARK: - View Extension for Toast
extension View {
    func showToast(_ message: String, type: ToastType = .success, duration: Double = AppConstants.toastDuration) -> some View {
        preference(key: ToastPreferenceKey.self, value: Toast(message: message, type: type, duration: duration))
    }
}

#Preview {
    VStack {
        Spacer()
        ToastView(toast: Toast(message: "Compound saved successfully", type: .success, duration: 2.5)) {}
        Spacer()
    }
    .background(Color(.systemGray6))
}
