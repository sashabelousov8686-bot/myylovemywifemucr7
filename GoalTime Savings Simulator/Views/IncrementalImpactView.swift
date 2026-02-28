import SwiftUI
import Charts

// MARK: - Incremental Impact: "What if I save a little more?"

struct IncrementalImpactView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoalEntity.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isPrimary == YES"),
        animation: .default
    )
    private var primaryGoals: FetchedResults<SavingsGoalEntity>
    
    @State private var additionalAmount: Double = 10
    @State private var selectedPreset: Int? = nil
    @AppStorage("selectedCurrency") private var currency = "USD"
    
    private var goal: SavingsGoalEntity? { primaryGoals.first }
    
    private var monthlyDeposit: Double { goal?.monthlyDeposit ?? 500 }
    private var currentSavings: Double { goal?.currentSavings ?? 0 }
    private var expectedReturn: Double { goal?.expectedReturn ?? 7.0 }
    private var inflationRate: Double { goal?.inflationRate ?? 3.0 }
    private var years: Double { goal?.yearsToTarget ?? 20 }
    
    private var impact: IncrementalResult {
        SavingsEngine.incrementalImpact(
            currentSavings: currentSavings,
            baseMonthlyDeposit: monthlyDeposit,
            additionalMonthly: additionalAmount,
            annualReturnRate: expectedReturn,
            annualInflationRate: inflationRate,
            years: years
        )
    }
    
    // Months saved if targeting the same amount as base FV
    private var monthsSaved: Int {
        guard let baseMonths = SavingsEngine.monthsToGoal(
            currentSavings: currentSavings,
            monthlyDeposit: monthlyDeposit,
            annualReturnRate: expectedReturn,
            targetAmount: impact.baseValue
        ),
              let boostedMonths = SavingsEngine.monthsToGoal(
            currentSavings: currentSavings,
            monthlyDeposit: monthlyDeposit + additionalAmount,
            annualReturnRate: expectedReturn,
            targetAmount: impact.baseValue
        ) else { return 0 }
        return max(0, baseMonths - boostedMonths)
    }
    
    struct ImpactPreset: Identifiable {
        let id: Int
        let amount: Double
        let label: String
        let icon: String
        let description: String
    }
    
    private var presets: [ImpactPreset] {
        let sym = CurrencyManager.currency(for: currency)?.symbol ?? "$"
        return [
            ImpactPreset(id: 0, amount: 5, label: "\(sym)5/mo", icon: "cup.and.saucer.fill", description: "Skip one coffee a week"),
            ImpactPreset(id: 1, amount: 10, label: "\(sym)10/mo", icon: "fork.knife", description: "One fewer lunch out"),
            ImpactPreset(id: 2, amount: 25, label: "\(sym)25/mo", icon: "bag.fill", description: "Reduce shopping"),
            ImpactPreset(id: 3, amount: 50, label: "\(sym)50/mo", icon: "car.fill", description: "Optimize transport"),
            ImpactPreset(id: 4, amount: 100, label: "\(sym)100/mo", icon: "tv.fill", description: "Cut a subscription"),
            ImpactPreset(id: 5, amount: 200, label: "\(sym)200/mo", icon: "house.fill", description: "Lifestyle change"),
        ]
    }
    
    @State private var showCreateGoal = false
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            if goal == nil {
                NoGoalView(
                    title: "Discover Your Impact",
                    subtitle: "Create a savings goal to see how small changes can make a huge difference."
                ) {
                    showCreateGoal = true
                }
            } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero
                    heroCard
                    
                    // Presets
                    presetGrid
                    
                    // Custom slider
                    customSlider
                    
                    // Comparison chart
                    comparisonChart
                    
                    // Detailed impact
                    detailCard
                    
                    DisclaimerBanner()
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            } // end else
        }
        .navigationTitle("Incremental Impact")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCreateGoal) {
            EditGoalSheet(goal: nil)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    // MARK: - Hero Card
    
    private var heroCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.growthGreen)
                .glow(AppTheme.Colors.growthGreen, radius: 10)
            
            Text("What if you saved a little more?")
                .font(AppTheme.Typography.title(22))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Text("Extra")
                    .foregroundStyle(.secondary)
                Text(CurrencyHelper.format(additionalAmount, currency: currency))
                    .foregroundStyle(AppTheme.Colors.growthGreen)
                    .fontWeight(.bold)
                Text("/month gives you")
                    .foregroundStyle(.secondary)
            }
            .font(AppTheme.Typography.body())
            
            AnimatedCounter(
                value: impact.extraGain,
                currency: currency,
                font: AppTheme.Typography.heroNumber(36),
                color: AppTheme.Colors.growthGreen
            )
            
            Text("more in \(Int(years)) years")
                .font(AppTheme.Typography.caption())
                .foregroundStyle(.secondary)
            
            if monthsSaved > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(AppTheme.Colors.neonBlue)
                    Text("Reach your goal **\(monthsSaved / 12) years \(monthsSaved % 12) months** sooner")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(.primary)
                }
                .padding(12)
                .background(AppTheme.Colors.neonBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
    
    // MARK: - Preset Grid
    
    private var presetGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Scenarios")
                .font(AppTheme.Typography.subtitle())
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(presets) { preset in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            additionalAmount = preset.amount
                            selectedPreset = preset.id
                        }
                        HapticManager.shared.light()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: preset.icon)
                                .font(.title3)
                                .foregroundStyle(selectedPreset == preset.id ? .white : AppTheme.Colors.neonBlue)
                            
                            Text(preset.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selectedPreset == preset.id ? .white : .primary)
                            
                            Text(preset.description)
                                .font(.system(size: 9))
                                .foregroundStyle(selectedPreset == preset.id ? .white.opacity(0.8) : .secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedPreset == preset.id
                            ? AnyShapeStyle(AppTheme.neonBlueGradient)
                            : AnyShapeStyle(Color.gray.opacity(0.1))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Slider
    
    private var customSlider: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(AppTheme.Colors.growthGreen)
                Text("Custom Amount")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(CurrencyHelper.format(additionalAmount, currency: currency))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.growthGreen)
            }
            
            Slider(value: $additionalAmount, in: 1...500, step: 5) {
                Text("Additional")
            } onEditingChanged: { editing in
                if editing {
                    HapticManager.shared.selection()
                    selectedPreset = nil
                }
            }
            .tint(AppTheme.Colors.growthGreen)
        }
        .padding(16)
        .glassCard()
    }
    
    // MARK: - Comparison Chart
    
    private var comparisonChart: some View {
        let baseData = SavingsEngine.growthCurve(
            currentSavings: currentSavings,
            monthlyDeposit: monthlyDeposit,
            annualReturnRate: expectedReturn,
            annualInflationRate: inflationRate,
            totalYears: Int(years)
        )
        
        let boostedData = SavingsEngine.growthCurve(
            currentSavings: currentSavings,
            monthlyDeposit: monthlyDeposit + additionalAmount,
            annualReturnRate: expectedReturn,
            annualInflationRate: inflationRate,
            totalYears: Int(years)
        )
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Base vs. Boosted")
                .font(AppTheme.Typography.subtitle())
            
            ComparisonChartView(
                dataA: baseData,
                dataB: boostedData,
                labelA: "Current Plan",
                labelB: "With Extra \(CurrencyHelper.format(additionalAmount, currency: currency))",
                currency: currency
            )
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Detail Card
    
    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Impact Breakdown")
                .font(AppTheme.Typography.subtitle())
            
            detailRow("Base future value", CurrencyHelper.format(impact.baseValue, currency: currency), AppTheme.Colors.neonBlue)
            detailRow("Boosted future value", CurrencyHelper.format(impact.boostedValue, currency: currency), AppTheme.Colors.growthGreen)
            
            Divider()
            
            detailRow("Your extra deposits", CurrencyHelper.format(impact.totalExtraDeposited, currency: currency), .secondary)
            detailRow("Compound bonus", CurrencyHelper.format(impact.compoundBonus, currency: currency), AppTheme.Colors.goalGold)
            detailRow("Total extra gain", CurrencyHelper.format(impact.extraGain, currency: currency), AppTheme.Colors.growthGreen)
            detailRow("Real extra gain", CurrencyHelper.format(impact.extraGainReal, currency: currency), AppTheme.Colors.purple)
        }
        .padding(20)
        .glassCard()
    }
    
    private func detailRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

#Preview {
    NavigationStack {
        IncrementalImpactView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
