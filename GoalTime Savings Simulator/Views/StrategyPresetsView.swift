import SwiftUI
import Charts

// MARK: - Strategy Presets: Conservative / Moderate / Aggressive

struct StrategyPresetsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoalEntity.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isPrimary == YES"),
        animation: .default
    )
    private var primaryGoals: FetchedResults<SavingsGoalEntity>
    
    @State private var selectedStrategy: Int = 1
    @State private var years: Double = 20
    @AppStorage("selectedCurrency") private var currency = "USD"
    
    private var goal: SavingsGoalEntity? { primaryGoals.first }
    private var currentSavings: Double { goal?.currentSavings ?? 0 }
    private var monthlyDeposit: Double { goal?.monthlyDeposit ?? 500 }
    private var inflationRate: Double { goal?.inflationRate ?? 3.0 }
    
    private let strategies: [Strategy] = [
        Strategy(name: "Conservative", description: "Simulates low-return scenario (~2.5%/yr). For educational comparison only.", annualReturn: 2.5, icon: "shield.fill", color: "neonBlue"),
        Strategy(name: "Moderate", description: "Simulates medium-return scenario (~6%/yr). For educational comparison only.", annualReturn: 6.0, icon: "scale.3d", color: "growthGreen"),
        Strategy(name: "Aggressive", description: "Simulates high-return scenario (~10%/yr). For educational comparison only.", annualReturn: 10.0, icon: "bolt.fill", color: "goalGold"),
    ]
    
    private func strategyColor(_ index: Int) -> Color {
        switch index {
        case 0: return AppTheme.Colors.neonBlue
        case 1: return AppTheme.Colors.growthGreen
        case 2: return AppTheme.Colors.goalGold
        default: return AppTheme.Colors.neonBlue
        }
    }
    
    private var results: [StrategyResult] {
        SavingsEngine.compareStrategies(
            currentSavings: currentSavings,
            monthlyDeposit: monthlyDeposit,
            annualInflationRate: inflationRate,
            years: years,
            strategies: strategies
        )
    }
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Strategy selector
                    strategySelector
                    
                    // Comparison chart
                    comparisonChart
                    
                    // Results grid
                    resultsGrid
                    
                    // Years slider
                    yearsSlider
                    
                    // Detailed comparison
                    detailedComparison
                    
                    DisclaimerBanner()
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Strategy Presets")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let goal = goal {
                years = min(goal.yearsToTarget, 50)
            }
        }
    }
    
    // MARK: - Strategy Selector
    
    private var strategySelector: some View {
        VStack(spacing: 16) {
            ForEach(Array(strategies.enumerated()), id: \.element.id) { index, strategy in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedStrategy = index
                    }
                    HapticManager.shared.medium()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: strategy.icon)
                            .font(.title2)
                            .foregroundStyle(strategyColor(index))
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(strategy.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                
                                Text("\(String(format: "%.1f", strategy.annualReturn))% / year")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(strategyColor(index))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(strategyColor(index).opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            
                            Text(strategy.description)
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: selectedStrategy == index ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedStrategy == index ? strategyColor(index) : .secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .fill(selectedStrategy == index
                                  ? strategyColor(index).opacity(0.08)
                                  : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .stroke(selectedStrategy == index
                                    ? strategyColor(index).opacity(0.3)
                                    : Color.gray.opacity(0.15), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Comparison Chart
    
    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Projected Growth by Strategy")
                .font(AppTheme.Typography.subtitle())
            
            Chart {
                ForEach(Array(strategies.enumerated()), id: \.element.id) { index, strategy in
                    let data = SavingsEngine.growthCurve(
                        currentSavings: currentSavings,
                        monthlyDeposit: monthlyDeposit,
                        annualReturnRate: strategy.annualReturn,
                        annualInflationRate: inflationRate,
                        totalYears: Int(years)
                    )
                    
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Year", point.year),
                            y: .value(strategy.name, point.nominalValue)
                        )
                        .foregroundStyle(strategyColor(index))
                        .lineStyle(StrokeStyle(lineWidth: selectedStrategy == index ? 3 : 1.5))
                        .interpolationMethod(.catmullRom)
                        .opacity(selectedStrategy == index ? 1.0 : 0.5)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(CurrencyHelper.formatCompact(v, currency: currency))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let yr = value.as(Double.self) {
                            Text("\(Int(yr))y")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartLegend(position: .bottom) {
                HStack(spacing: 12) {
                    ForEach(Array(strategies.enumerated()), id: \.element.id) { index, strategy in
                        LegendItem(color: strategyColor(index), label: strategy.name)
                    }
                }
                .font(.caption2)
            }
            .frame(height: 260)
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Results Grid
    
    private var resultsGrid: some View {
        HStack(spacing: 12) {
            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                VStack(spacing: 8) {
                    Image(systemName: strategies[index].icon)
                        .font(.title3)
                        .foregroundStyle(strategyColor(index))
                    
                    Text(CurrencyHelper.formatCompact(result.futureValue, currency: currency))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("Real: \(CurrencyHelper.formatCompact(result.realValue, currency: currency))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    Text(strategies[index].name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(strategyColor(index))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .glassCard()
            }
        }
    }
    
    // MARK: - Years Slider
    
    private var yearsSlider: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.Colors.neonBlue)
                Text("Time Horizon")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(years)) years")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.neonBlue)
            }
            
            Slider(value: $years, in: 1...50, step: 1) {
                Text("Years")
            } onEditingChanged: { editing in
                if editing { HapticManager.shared.selection() }
            }
            .tint(AppTheme.Colors.neonBlue)
        }
        .padding(16)
        .glassCard()
    }
    
    // MARK: - Detailed Comparison
    
    private var detailedComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Comparison")
                .font(AppTheme.Typography.subtitle())
            
            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                let deposited = currentSavings + monthlyDeposit * years * 12
                let interest = result.futureValue - deposited
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: strategies[index].icon)
                            .foregroundStyle(strategyColor(index))
                        Text(strategies[index].name)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text(CurrencyHelper.format(result.futureValue, currency: currency))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(strategyColor(index))
                    }
                    
                    HStack(spacing: 16) {
                        miniStat("Compound Interest", CurrencyHelper.formatCompact(interest, currency: currency))
                        miniStat("Real Value", CurrencyHelper.formatCompact(result.realValue, currency: currency))
                    }
                }
                .padding(14)
                .background(strategyColor(index).opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
            }
        }
        .padding(20)
        .glassCard()
    }
    
    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
        }
    }
}

#Preview {
    NavigationStack {
        StrategyPresetsView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
