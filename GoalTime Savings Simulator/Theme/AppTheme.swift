import SwiftUI

// MARK: - Design System: Clean & Futuristic Premium

struct AppTheme {
    
    // MARK: - Colors
    
    struct Colors {
        // Primary backgrounds
        static let darkGradientStart = Color(hex: "0F1117")
        static let darkGradientEnd = Color(hex: "1A1F2E")
        static let lightBackground = Color(hex: "F8F9FA")
        static let lightCardBackground = Color.white
        static let darkCardBackground = Color(hex: "1E2335")
        
        // Accents
        static let neonBlue = Color(hex: "00D4FF")
        static let growthGreen = Color(hex: "00E676")
        static let goalGold = Color(hex: "FFD700")
        static let alertRed = Color(hex: "FF5252")
        static let purple = Color(hex: "BB86FC")
        static let orange = Color(hex: "FF9800")
        
        // Chart colors
        static let chartNominal = neonBlue
        static let chartReal = growthGreen
        static let chartDeposits = Color(hex: "546E7A")
        static let chartSecondary = purple
        
        // Text
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let accentText = neonBlue
    }
    
    // MARK: - Gradients
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Colors.darkGradientStart, Colors.darkGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var neonBlueGradient: LinearGradient {
        LinearGradient(
            colors: [Colors.neonBlue, Colors.neonBlue.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var growthGradient: LinearGradient {
        LinearGradient(
            colors: [Colors.growthGreen, Colors.neonBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [Colors.goalGold, Colors.orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Corner Radius
    
    struct Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 20
        static let large: CGFloat = 28
        static let extraLarge: CGFloat = 32
    }
    
    // MARK: - Typography
    
    struct Typography {
        static func heroNumber(_ size: CGFloat = 42) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        
        static func title(_ size: CGFloat = 24) -> Font {
            .system(size: size, weight: .bold, design: .default)
        }
        
        static func subtitle(_ size: CGFloat = 17) -> Font {
            .system(size: size, weight: .medium, design: .default)
        }
        
        static func body(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }
        
        static func caption(_ size: CGFloat = 12) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }
        
        static let disclaimer: Font = .system(size: 10, weight: .regular, design: .default)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - View Modifiers

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(colorScheme == .dark
                          ? AppTheme.Colors.darkCardBackground.opacity(0.8)
                          : AppTheme.Colors.lightCardBackground.opacity(0.95))
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 12, y: 4)
            }
    }
}

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius * 2)
    }
}

struct PremiumButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
    
    func glow(_ color: Color = AppTheme.Colors.neonBlue, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Keyboard Dismiss Modifier

struct DismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardModifier())
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: Int, CaseIterable {
    case system = 0
    case dark = 1
    case light = 2
    
    var label: String {
        switch self {
        case .system: return "System"
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

// MARK: - Animated Background

struct AnimatedMeshBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if colorScheme == .dark {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
        } else {
            AppTheme.Colors.lightBackground
                .ignoresSafeArea()
        }
    }
}

// MARK: - Disclaimer Banner

struct DisclaimerBanner: View {
    var body: some View {
        Text("This is a private personal savings simulation tool for educational purposes. Not financial advice or investment recommendation.")
            .font(AppTheme.Typography.disclaimer)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.vertical, 6)
    }
}

// MARK: - Currency Formatter Helper

struct CurrencyHelper {
    static func symbol(for code: String) -> String {
        let locale = Locale.availableIdentifiers
            .map { Locale(identifier: $0) }
            .first { $0.currency?.identifier == code }
        return locale?.currencySymbol ?? code
    }
    
    static func format(_ value: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        if value >= 1_000_000 {
            formatter.maximumFractionDigits = 0
        }
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency) \(Int(value))"
    }
    
    static func formatCompact(_ value: Double, currency: String) -> String {
        if value >= 1_000_000 {
            return "\(CurrencyHelper.symbol(for: currency))\(String(format: "%.1fM", value / 1_000_000))"
        } else if value >= 1_000 {
            return "\(CurrencyHelper.symbol(for: currency))\(String(format: "%.0fK", value / 1_000))"
        }
        return format(value, currency: currency)
    }
}
