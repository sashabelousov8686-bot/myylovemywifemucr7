import SwiftUI
import Charts

// MARK: - Inflation Adjuster

struct InflationAdjusterView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoalEntity.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isPrimary == YES"),
        animation: .default
    )
    private var primaryGoals: FetchedResults<SavingsGoalEntity>
    
    @State private var inflationRate: Double = 3.0
    @State private var targetAmount: Double = 100_000
    @State private var years: Double = 20
    @AppStorage("selectedCurrency") private var currency = "USD"
    
    private var goal: SavingsGoalEntity? { primaryGoals.first }
    
    // The same goal in inflated dollars
    private var inflatedCost: Double {
        SavingsEngine.inflatedGoalCost(
            currentCost: targetAmount,
            annualInflationRate: inflationRate,
            years: years
        )
    }
    
    // What today's future value is worth in today's dollars
    private var purchasingPowerLost: Double {
        inflatedCost - targetAmount
    }
    
    // Year-by-year inflation data
    private var inflationData: [(year: Int, todayCost: Double, futureCost: Double)] {
        (0...Int(years)).map { yr in
            let future = SavingsEngine.inflatedGoalCost(currentCost: targetAmount, annualInflationRate: inflationRate, years: Double(yr))
            return (yr, targetAmount, future)
        }
    }
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero
                    heroCard
                    
                    // Inflation chart
                    inflationChart
                    
                    // Controls
                    controlsCard
                    
                    // Year breakdown
                    yearBreakdown
                    
                    DisclaimerBanner()
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Inflation Adjuster")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadFromGoal() }
    }
    
    // MARK: - Hero Card
    
    private var heroCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.Colors.orange)
                .glow(AppTheme.Colors.orange, radius: 10)
            
            Text("Inflation Erodes Your Savings")
                .font(AppTheme.Typography.title(20))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                Text("Your goal today")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
                
                Text(CurrencyHelper.format(targetAmount, currency: currency))
                    .font(AppTheme.Typography.heroNumber(32))
                    .foregroundStyle(.primary)
                
                Image(systemName: "arrow.down")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.alertRed)
                
                Text("will cost in \(Int(years)) years")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
                
                AnimatedCounter(
                    value: inflatedCost,
                    currency: currency,
                    font: AppTheme.Typography.heroNumber(36),
                    color: AppTheme.Colors.alertRed
                )
                
                Text("at \(String(format: "%.1f%%", inflationRate)) annual inflation")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
            }
            
            // Extra cost pill
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppTheme.Colors.orange)
                Text("You need \(CurrencyHelper.format(purchasingPowerLost, currency: currency)) MORE to keep the same purchasing power")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(AppTheme.Colors.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
    
    // MARK: - Inflation Chart
    
    private var inflationChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Over Time")
                .font(AppTheme.Typography.subtitle())
            
            Chart {
                // Today's cost line (flat)
                ForEach(inflationData, id: \.year) { item in
                    LineMark(
                        x: .value("Year", item.year),
                        y: .value("Today", item.todayCost)
                    )
                    .foregroundStyle(AppTheme.Colors.growthGreen)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
                
                // Inflated cost
                ForEach(inflationData, id: \.year) { item in
                    AreaMark(
                        x: .value("Year", item.year),
                        y: .value("Future Cost", item.futureCost)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [AppTheme.Colors.alertRed.opacity(0.25), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Year", item.year),
                        y: .value("Future Cost", item.futureCost)
                    )
                    .foregroundStyle(AppTheme.Colors.alertRed)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
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
                AxisMarks { value in
                    AxisValueLabel {
                        if let yr = value.as(Int.self) {
                            Text("\(yr)y")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartLegend(position: .bottom) {
                HStack(spacing: 16) {
                    LegendItem(color: AppTheme.Colors.growthGreen, label: "Today's Cost")
                    LegendItem(color: AppTheme.Colors.alertRed, label: "Inflated Cost")
                }
                .font(.caption2)
            }
            .frame(height: 240)
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Controls
    
    private var controlsCard: some View {
        VStack(spacing: 16) {
            // Target amount
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "target")
                        .foregroundStyle(AppTheme.Colors.goalGold)
                    Text("Goal Amount")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyHelper.format(targetAmount, currency: currency))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.goalGold)
                }
                
                Slider(value: $targetAmount, in: 1000...5_000_000, step: 5000)
                    .tint(AppTheme.Colors.goalGold)
            }
            
            // Inflation rate
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
                
                Slider(value: $inflationRate, in: 0...15, step: 0.5)
                    .tint(AppTheme.Colors.orange)
            }
            
            // Years
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
                
                Slider(value: $years, in: 1...50, step: 1)
                    .tint(AppTheme.Colors.neonBlue)
            }
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Year Breakdown
    
    private var yearBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestone Costs")
                .font(AppTheme.Typography.subtitle())
            
            let milestones = [5, 10, 15, 20, 25, 30].filter { $0 <= Int(years) }
            
            ForEach(milestones, id: \.self) { yr in
                let cost = SavingsEngine.inflatedGoalCost(currentCost: targetAmount, annualInflationRate: inflationRate, years: Double(yr))
                let extra = cost - targetAmount
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Year \(yr)")
                            .font(.system(size: 14, weight: .semibold))
                        Text("+\(CurrencyHelper.format(extra, currency: currency))")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.alertRed)
                    }
                    
                    Spacer()
                    
                    Text(CurrencyHelper.format(cost, currency: currency))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 8)
                
                if yr != milestones.last {
                    Divider()
                }
            }
        }
        .padding(20)
        .glassCard()
    }
    
    private func loadFromGoal() {
        guard let goal = goal else { return }
        inflationRate = goal.inflationRate
        targetAmount = goal.targetAmount
        years = min(goal.yearsToTarget, 50)
        currency = goal.currency
    }
}

#Preview {
    NavigationStack {
        InflationAdjusterView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
