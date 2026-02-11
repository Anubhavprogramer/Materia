import SwiftUI

/// A premium "liquid glass" button style with true frosted glass morphism effect.
/// Uses blur, gradient, and material layers to create an elegant glass appearance.
struct LiquidGlassButtonStyle: ButtonStyle {
    enum Size {
        case small
        case regular
        case large

        var verticalPadding: CGFloat {
            switch self {
            case .small: return AppConstants.smallPadding
            case .regular: return AppConstants.defaultPadding
            case .large: return AppConstants.largePadding
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return AppConstants.smallPadding
            case .regular: return AppConstants.defaultPadding
            case .large: return AppConstants.largePadding
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return AppConstants.smallCornerRadius
            case .regular: return AppConstants.defaultCornerRadius
            case .large: return AppConstants.largeCornerRadius
            }
        }
    }

    var size: Size = .regular
    var color: Color = .blue
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(Color.white)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    // Layer 1: Frosted glass background with material effect
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .blur(radius: 0.5)

//                     Layer 2: Color gradient overlay
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(isEnabled ? 0.7 : 0.3),
                                    color.opacity(isEnabled ? 0.5 : 0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Layer 3: Subtle inner glow
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.2))
                        .blur(radius: 8)

//                     Layer 4: Light reflection / specular highlight
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(configuration.isPressed ? 0.3 : 0.5),
                                    Color.white.opacity(0.08)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            }
            .overlay {
                // Outer rim with subtle border
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            }
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? 0.1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: configuration.isPressed)
    }
}

extension View {
//     Convenience wrapper for liquid glass button style.
//     - Parameters:
//       - color: The primary color for the button gradient and glow
//       - size: The button size (small, regular, large)
//       - isEnabled: Whether the button is enabled
    func liquidGlassButton(
        color: Color = .blue,
        size: LiquidGlassButtonStyle.Size = .regular,
        isEnabled: Bool = true
    ) -> some View {
        self.buttonStyle(LiquidGlassButtonStyle(size: size, color: color, isEnabled: isEnabled))
    }
}
