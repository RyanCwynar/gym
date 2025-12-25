import SwiftUI

struct GymTheme {
    // Main brand colors - Bold, energetic gym aesthetic
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let accent = Color("Accent")
    
    // Semantic colors
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let surfaceElevated = Color("SurfaceElevated")
    static let text = Color("Text")
    static let textSecondary = Color("TextSecondary")
    
    // Status colors
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "FF6B35"), Color(hex: "F7C59F")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkGradient = LinearGradient(
        colors: [Color(hex: "1A1A2E"), Color(hex: "16213E")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color(hex: "2D2D44"), Color(hex: "1F1F32")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "00D9FF"), Color(hex: "00A8CC")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .black, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        
        // Special typography
        static let statValue = Font.system(size: 42, weight: .black, design: .rounded)
        static let cardTitle = Font.system(size: 18, weight: .bold, design: .rounded)
        static let buttonText = Font.system(size: 17, weight: .bold, design: .rounded)
    }
    
    // Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // Corner radius
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 24
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Fallback colors when asset catalog not available
extension Color {
    static let gymPrimary = Color(hex: "FF6B35")
    static let gymSecondary = Color(hex: "00D9FF")
    static let gymAccent = Color(hex: "FFE66D")
    static let gymBackground = Color(hex: "0D0D0D")
    static let gymSurface = Color(hex: "1A1A2E")
    static let gymSurfaceElevated = Color(hex: "2D2D44")
    static let gymText = Color(hex: "FFFFFF")
    static let gymTextSecondary = Color(hex: "A0A0A0")
    static let gymSuccess = Color(hex: "4CAF50")
    static let gymWarning = Color(hex: "FFC107")
    static let gymError = Color(hex: "FF5252")
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
    }
}

struct GlassStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.large))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GymTheme.Typography.buttonText)
            .foregroundColor(.black)
            .padding(.horizontal, GymTheme.Spacing.lg)
            .padding(.vertical, GymTheme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FF6B35"), Color(hex: "FF8C5A")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GymTheme.Typography.buttonText)
            .foregroundColor(Color.gymPrimary)
            .padding(.horizontal, GymTheme.Spacing.lg)
            .padding(.vertical, GymTheme.Spacing.md)
            .background(Color.gymPrimary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: GymTheme.Radius.medium)
                    .stroke(Color.gymPrimary, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func glassStyle() -> some View {
        modifier(GlassStyle())
    }
}

