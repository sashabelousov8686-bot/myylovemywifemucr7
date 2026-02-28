import SwiftUI

// MARK: - Quick Financial Tools

struct QuickToolsView: View {
    @State private var selectedTool = 0
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Tool selector
                    toolSelector
                    
                    // Active tool
                    switch selectedTool {
                    case 0:
                        RuleOf72Tool()
                    case 1:
                        SavingsRateCalculator()
                    case 2:
                        InflationErosionTool()
                    default:
                        RuleOf72Tool()
                    }
                    
                    DisclaimerBanner()
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Quick Tools")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Tool Selector
    
    private var toolSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                toolTab(index: 0, title: "Rule of 72", icon: "divide.circle.fill", color: AppTheme.Colors.growthGreen)
                toolTab(index: 1, title: "Savings Rate", icon: "percent", color: AppTheme.Colors.neonBlue)
                toolTab(index: 2, title: "Inflation Erosion", icon: "flame.fill", color: AppTheme.Colors.orange)
            }
        }
    }
    
    private func toolTab(index: Int, title: String, icon: String, color: Color) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTool = index
            }
            HapticManager.shared.light()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(selectedTool == index ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                selectedTool == index
                ? AnyShapeStyle(color.gradient)
                : AnyShapeStyle(color.opacity(0.12))
            )
            .clipShape(Capsule())
        }
        .accessibilityLabel("\(title) calculator")
        .accessibilityAddTraits(selectedTool == index ? .isSelected : [])
    }
}

// MARK: - Rule of 72 Tool

struct RuleOf72Tool: View {
    @State private var annualRate: Double = 7.0
    @AppStorage("selectedCurrency") private var currency = "USD"
    @State private var initialAmount: Double = 10_000
    
    private var doublingYears: Double {
        guard annualRate > 0 else { return .infinity }
        return 72.0 / annualRate
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Hero
            VStack(spacing: 12) {
                Image(systemName: "divide.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.Colors.growthGreen)
                    .glow(AppTheme.Colors.growthGreen, radius: 10)
                
                Text("Rule of 72")
                    .font(AppTheme.Typography.title(22))
                
                Text("Quickly estimate how long it takes for your money to double at a given return rate.")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .glassCard()
            
            // Result
            VStack(spacing: 16) {
                Text("Your money doubles in")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                if annualRate > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", doublingYears))
                            .font(AppTheme.Typography.heroNumber(48))
                            .foregroundStyle(AppTheme.Colors.growthGreen)
                            .contentTransition(.numericText(value: doublingYears))
                            .animation(.easeInOut, value: doublingYears)
                        
                        Text("years")
                            .font(AppTheme.Typography.title(20))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("∞")
                        .font(AppTheme.Typography.heroNumber(48))
                        .foregroundStyle(.secondary)
                }
                
                // Doubling timeline
                if annualRate > 0 {
                    VStack(spacing: 8) {
                        let doublings = min(5, Int(50.0 / doublingYears))
                        ForEach(0..<doublings, id: \.self) { i in
                            let years = doublingYears * Double(i + 1)
                            let amount = initialAmount * pow(2.0, Double(i + 1))
                            
                            HStack {
                                Text("Year \(Int(years))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text("×\(Int(pow(2.0, Double(i + 1))))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.Colors.growthGreen)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.Colors.growthGreen.opacity(0.12))
                                        .clipShape(Capsule())
                                    
                                    Text(CurrencyHelper.formatCompact(amount, currency: currency))
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                }
                            }
                            
                            if i < doublings - 1 {
                                Divider().opacity(0.3)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                }
            }
            .padding(20)
            .glassCard()
            
            // Rate slider
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(AppTheme.Colors.growthGreen)
                    Text("Annual Return Rate")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f%%", annualRate))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.growthGreen)
                }
                
                Slider(value: $annualRate, in: 0.5...20, step: 0.5) {
                    Text("Rate")
                } onEditingChanged: { editing in
                    if editing { HapticManager.shared.selection() }
                }
                .tint(AppTheme.Colors.growthGreen)
                .accessibilityLabel("Annual return rate")
                .accessibilityValue("\(String(format: "%.1f", annualRate)) percent")
            }
            .padding(16)
            .glassCard()
            
            // Starting amount slider
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "banknote.fill")
                        .foregroundStyle(AppTheme.Colors.goalGold)
                    Text("Starting Amount")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyHelper.format(initialAmount, currency: currency))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.goalGold)
                }
                
                Slider(value: $initialAmount, in: 1000...500_000, step: 1000) {
                    Text("Amount")
                } onEditingChanged: { editing in
                    if editing { HapticManager.shared.selection() }
                }
                .tint(AppTheme.Colors.goalGold)
                .accessibilityLabel("Starting amount")
                .accessibilityValue(CurrencyHelper.format(initialAmount, currency: currency))
            }
            .padding(16)
            .glassCard()
        }
    }
}

// MARK: - Savings Rate Calculator

struct SavingsRateCalculator: View {
    @State private var monthlyIncome: Double = 5000
    @State private var monthlySavings: Double = 1000
    @AppStorage("selectedCurrency") private var currency = "USD"
    
    private var savingsRate: Double {
        guard monthlyIncome > 0 else { return 0 }
        return (monthlySavings / monthlyIncome) * 100
    }
    
    private var rateColor: Color {
        if savingsRate >= 30 { return AppTheme.Colors.growthGreen }
        else if savingsRate >= 20 { return AppTheme.Colors.neonBlue }
        else if savingsRate >= 10 { return AppTheme.Colors.goalGold }
        else { return AppTheme.Colors.alertRed }
    }
    
    private var rateLabel: String {
        if savingsRate >= 30 { return "Excellent" }
        else if savingsRate >= 20 { return "Good" }
        else if savingsRate >= 10 { return "Fair" }
        else if savingsRate > 0 { return "Needs Work" }
        else { return "None" }
    }
    
    // Estimate years to financial independence (25× annual expenses)
    private var yearsToFI: Double? {
        guard monthlySavings > 0 else { return nil }
        let annualSavings = monthlySavings * 12
        let annualExpenses = (monthlyIncome - monthlySavings) * 12
        let target = annualExpenses * 25 // 4% rule
        guard target > 0 else { return 0 }
        
        // Months to goal at 7% return
        if let months = SavingsEngine.monthsToGoal(
            currentSavings: 0,
            monthlyDeposit: monthlySavings,
            annualReturnRate: 7.0,
            targetAmount: target
        ) {
            return Double(months) / 12.0
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Hero
            VStack(spacing: 12) {
                Image(systemName: "percent")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.Colors.neonBlue)
                    .glow(AppTheme.Colors.neonBlue, radius: 10)
                
                Text("Savings Rate Calculator")
                    .font(AppTheme.Typography.title(22))
                
                Text("Find out what percentage of your income you're saving and what it means for your future.")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .glassCard()
            
            // Result
            VStack(spacing: 16) {
                Text("Your Savings Rate")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", savingsRate))
                        .font(AppTheme.Typography.heroNumber(56))
                        .foregroundStyle(rateColor)
                        .contentTransition(.numericText(value: savingsRate))
                        .animation(.easeInOut, value: savingsRate)
                    
                    Text("%")
                        .font(AppTheme.Typography.title(28))
                        .foregroundStyle(rateColor)
                }
                
                Text(rateLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(rateColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(rateColor.opacity(0.12))
                    .clipShape(Capsule())
                
                // FI estimate
                if let fi = yearsToFI {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.checkered")
                            .foregroundStyle(AppTheme.Colors.goalGold)
                        Text("~\(Int(fi)) years to financial independence")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(AppTheme.Colors.goalGold.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Breakdown
                HStack(spacing: 12) {
                    miniBlock("Monthly Savings", CurrencyHelper.format(monthlySavings, currency: currency), AppTheme.Colors.growthGreen)
                    miniBlock("Monthly Expenses", CurrencyHelper.format(max(0, monthlyIncome - monthlySavings), currency: currency), AppTheme.Colors.orange)
                    miniBlock("Annual Savings", CurrencyHelper.format(monthlySavings * 12, currency: currency), AppTheme.Colors.neonBlue)
                }
            }
            .padding(20)
            .glassCard()
            
            // Income slider
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "briefcase.fill")
                        .foregroundStyle(AppTheme.Colors.neonBlue)
                    Text("Monthly Income (after tax)")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyHelper.format(monthlyIncome, currency: currency))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.neonBlue)
                }
                
                Slider(value: $monthlyIncome, in: 500...50000, step: 100) {
                    Text("Income")
                } onEditingChanged: { editing in
                    if editing { HapticManager.shared.selection() }
                }
                .tint(AppTheme.Colors.neonBlue)
                .onChange(of: monthlyIncome) { _, newVal in
                    if monthlySavings > newVal {
                        monthlySavings = newVal
                    }
                }
                .accessibilityLabel("Monthly income after tax")
                .accessibilityValue(CurrencyHelper.format(monthlyIncome, currency: currency))
            }
            .padding(16)
            .glassCard()
            
            // Savings slider
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "banknote.fill")
                        .foregroundStyle(AppTheme.Colors.growthGreen)
                    Text("Monthly Savings")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyHelper.format(monthlySavings, currency: currency))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.growthGreen)
                }
                
                Slider(value: $monthlySavings, in: 0...monthlyIncome, step: 50) {
                    Text("Savings")
                } onEditingChanged: { editing in
                    if editing { HapticManager.shared.selection() }
                }
                .tint(AppTheme.Colors.growthGreen)
                .accessibilityLabel("Monthly savings amount")
                .accessibilityValue(CurrencyHelper.format(monthlySavings, currency: currency))
            }
            .padding(16)
            .glassCard()
            
            // Guideline
            guidelineCard
        }
    }
    
    private func miniBlock(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var guidelineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Savings Rate Guidelines")
                .font(AppTheme.Typography.subtitle())
            
            guidelineRow("Below 10%", "Consider reducing expenses to build savings", AppTheme.Colors.alertRed)
            guidelineRow("10–19%", "A good start, keep building momentum", AppTheme.Colors.goalGold)
            guidelineRow("20–29%", "Solid savings rate for long-term goals", AppTheme.Colors.neonBlue)
            guidelineRow("30%+", "Excellent — significantly accelerates wealth building", AppTheme.Colors.growthGreen)
        }
        .padding(20)
        .glassCard()
    }
    
    private func guidelineRow(_ range: String, _ description: String, _ color: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(range)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 70, alignment: .leading)
            
            Text(description)
                .font(AppTheme.Typography.caption())
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Inflation Erosion Tool

struct InflationErosionTool: View {
    @State private var amount: Double = 10_000
    @State private var inflationRate: Double = 3.0
    @AppStorage("selectedCurrency") private var currency = "USD"
    
    private var erosionData: [(year: Int, value: Double)] {
        (0...30).map { year in
            let eroded = amount / pow(1 + inflationRate / 100.0, Double(year))
            return (year, eroded)
        }
    }
    
    private var value10y: Double { amount / pow(1 + inflationRate / 100.0, 10) }
    private var value20y: Double { amount / pow(1 + inflationRate / 100.0, 20) }
    private var value30y: Double { amount / pow(1 + inflationRate / 100.0, 30) }
    
    var body: some View {
        VStack(spacing: 20) {
            // Hero
            VStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.Colors.orange)
                    .glow(AppTheme.Colors.orange, radius: 10)
                
                Text("Inflation Erosion")
                    .font(AppTheme.Typography.title(22))
                
                Text("See how inflation silently reduces the purchasing power of money sitting idle.")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .glassCard()
            
            // Result cards
            VStack(spacing: 12) {
                Text("\(CurrencyHelper.format(amount, currency: currency)) today is worth...")
                    .font(AppTheme.Typography.subtitle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    erosionCard("10 Years", value10y, amount)
                    erosionCard("20 Years", value20y, amount)
                    erosionCard("30 Years", value30y, amount)
                }
            }
            .padding(20)
            .glassCard()
            
            // Amount slider
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "banknote.fill")
                        .foregroundStyle(AppTheme.Colors.goalGold)
                    Text("Amount")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyHelper.format(amount, currency: currency))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.goalGold)
                }
                
                Slider(value: $amount, in: 1000...1_000_000, step: 1000) {
                    Text("Amount")
                } onEditingChanged: { editing in
                    if editing { HapticManager.shared.selection() }
                }
                .tint(AppTheme.Colors.goalGold)
                .accessibilityLabel("Amount to analyze")
                .accessibilityValue(CurrencyHelper.format(amount, currency: currency))
            }
            .padding(16)
            .glassCard()
            
            // Inflation slider
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(AppTheme.Colors.orange)
                    Text("Inflation Rate")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f%%", inflationRate))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.orange)
                }
                
                Slider(value: $inflationRate, in: 0.5...15, step: 0.5) {
                    Text("Rate")
                } onEditingChanged: { editing in
                    if editing { HapticManager.shared.selection() }
                }
                .tint(AppTheme.Colors.orange)
                .accessibilityLabel("Annual inflation rate")
                .accessibilityValue("\(String(format: "%.1f", inflationRate)) percent")
            }
            .padding(16)
            .glassCard()
            
            // Takeaway
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppTheme.Colors.goalGold)
                    .font(.subheadline)
                
                Text("Money that isn't growing is shrinking. Inflation means idle savings lose purchasing power every year. Even a conservative investment that beats inflation protects your wealth.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .padding(16)
            .glassCard()
        }
    }
    
    private func erosionCard(_ label: String, _ value: Double, _ original: Double) -> some View {
        let loss = (1 - value / original) * 100
        
        return VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text(CurrencyHelper.formatCompact(value, currency: currency))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.alertRed)
            
            Text("-\(Int(loss))%")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.Colors.alertRed)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.Colors.alertRed.opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
    }
}

#Preview {
    NavigationStack {
        QuickToolsView()
    }
}
