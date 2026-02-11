import SwiftUI

/// A reusable “liquid glass” button style.
/// Uses blur + translucent material + subtle highlight to mimic glass.
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
    var tint: Color = .blue
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    // Glass base
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Tint wash
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .fill(tint.opacity(isEnabled ? 0.55 : 0.25))

                    // Specular highlight
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(configuration.isPressed ? 0.25 : 0.45),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
            .overlay {
                // Outer rim
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
            .opacity(isEnabled ? 1.0 : 0.7)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

extension View {
    /// Convenience wrapper so we can keep call sites clean.
    func liquidGlassPrimaryButton(tint: Color = .blue, size: LiquidGlassButtonStyle.Size = .regular, isEnabled: Bool = true) -> some View {
        self.buttonStyle(LiquidGlassButtonStyle(size: size, tint: tint, isEnabled: isEnabled))
    }
}
