import SwiftUI

// MARK: - Animated Number Counter

struct AnimatedCounter: View {
    let value: Double
    let currency: String
    let font: Font
    let color: Color
    
    @State private var displayedValue: Double = 0
    @State private var animationTimer: Timer?
    
    init(
        value: Double,
        currency: String = "USD",
        font: Font = AppTheme.Typography.heroNumber(),
        color: Color = AppTheme.Colors.neonBlue
    ) {
        self.value = value
        self.currency = currency
        self.font = font
        self.color = color
    }
    
    var body: some View {
        Text(CurrencyHelper.format(displayedValue, currency: currency))
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayedValue))
            .onChange(of: value, initial: true) { oldVal, newVal in
                withAnimation(.easeInOut(duration: 0.6)) {
                    displayedValue = newVal
                }
            }
    }
}

// MARK: - Animated Percentage Counter

struct AnimatedPercentage: View {
    let value: Double
    let font: Font
    let color: Color
    
    @State private var displayedValue: Double = 0
    
    init(
        value: Double,
        font: Font = AppTheme.Typography.heroNumber(28),
        color: Color = AppTheme.Colors.growthGreen
    ) {
        self.value = value
        self.font = font
        self.color = color
    }
    
    var body: some View {
        Text("\(displayedValue, specifier: "%.1f")%")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayedValue))
            .onChange(of: value, initial: true) { _, newVal in
                withAnimation(.easeInOut(duration: 0.5)) {
                    displayedValue = newVal
                }
            }
    }
}

// MARK: - Animated Progress Ring

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: LinearGradient
    let size: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        gradient: LinearGradient = AppTheme.growthGradient,
        size: CGFloat = 160
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(animatedProgress, 1.0)))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: AppTheme.Colors.neonBlue.opacity(0.3), radius: 6)
        }
        .frame(width: size, height: size)
        .onChange(of: progress, initial: true) { _, newVal in
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = newVal
            }
        }
    }
}

// MARK: - Glowing Dot Indicator

struct GlowDot: View {
    let color: Color
    let size: CGFloat
    @State private var isGlowing = false
    
    init(color: Color = AppTheme.Colors.growthGreen, size: CGFloat = 10) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(isGlowing ? 0.6 : 0.2), radius: isGlowing ? 8 : 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

#Preview {
    VStack(spacing: 24) {
        AnimatedCounter(value: 250_000)
        AnimatedPercentage(value: 72.5)
        ProgressRing(progress: 0.65)
        GlowDot()
    }
    .padding()
    .background(Color.black)
}
