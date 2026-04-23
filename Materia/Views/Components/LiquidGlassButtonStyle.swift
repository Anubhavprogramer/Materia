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
            .foregroundStyle(AppColors.actionButtonText)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(width: 330)
            .glassEffect()
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
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
