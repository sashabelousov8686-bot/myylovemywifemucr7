import SwiftUI
import Charts

// MARK: - Time Machine Simulator (Main Working Screen)

struct TimeMachineView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoalEntity.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isPrimary == YES"),
        animation: .default
    )
    private var primaryGoals: FetchedResults<SavingsGoalEntity>
    
    // Simulator parameters
    @State private var monthlyDeposit: Double = 500
    @State private var years: Double = 20
    @State private var expectedReturn: Double = 7.0
    @State private var inflationRate: Double = 3.0
    @State private var currentSavings: Double = 0
    @AppStorage("selectedCurrency") private var currency = "USD"
    
    // UI state
    @State private var showRealValues = true
    @State private var selectedYearMark: Int? = nil
    @State private var hasLoaded = false
    
    private var goal: SavingsGoalEntity? { primaryGoals.first }
    
    // Computed chart data
    private var chartData: [GrowthPoint] {
        SavingsEngine.growthCurve(
            currentSavings: currentSavings,
            monthlyDeposit: monthlyDeposit,
            annualReturnRate: expectedReturn,
            annualInflationRate: inflationRate,
            totalYears: Int(years)
        )
    }
    
    private var fv: Double {
        SavingsEngine.futureValue(
            currentSavings: currentSavings,
            monthlyDeposit: monthlyDeposit,
            annualReturnRate: expectedReturn,
            years: years
        )
    }
    
    private var rv: Double {
        SavingsEngine.realValue(futureValue: fv, annualInflationRate: inflationRate, years: years)
    }
    
    private var totalDeposited: Double {
        currentSavings + monthlyDeposit * years * 12
    }
    
    private var compoundInterest: Double {
        fv - totalDeposited
    }
    
    @State private var showCreateGoal = false
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            if goal == nil {
                NoGoalView(
                    title: "Time Machine Awaits",
                    subtitle: "Create a savings goal to simulate your financial future across decades."
                ) {
                    showCreateGoal = true
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Hero numbers
                        heroSection
                        
                        // Chart
                        chartSection
                        
                        // Milestone previews (10/20/30 years)
                        milestonePreviews
                        
                        // Sliders
                        slidersSection
                        
                        // Year-by-year detail table
                        yearByYearSection
                        
                        // Breakdown
                        breakdownSection
                        
                        DisclaimerBanner()
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                }
            }
        }
        .navigationTitle("Time Machine")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadFromGoal() }
        .sheet(isPresented: $showCreateGoal) {
            EditGoalSheet(goal: nil)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 8) {
            Text("Future Value")
                .font(AppTheme.Typography.caption())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.2)
            
            AnimatedCounter(
                value: fv,
                currency: currency,
                font: AppTheme.Typography.heroNumber(40),
                color: AppTheme.Colors.neonBlue
            )
            .glow(AppTheme.Colors.neonBlue, radius: 6)
            
            if showRealValues {
                HStack(spacing: 4) {
                    Text("Real purchasing power:")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(.secondary)
                    Text(CurrencyHelper.format(rv, currency: currency))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.growthGreen)
                }
            }
            
            Text("in \(Int(years)) years")
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Growth Projection")
                    .font(AppTheme.Typography.subtitle())
                
                Spacer()
                
                Toggle("Real", isOn: $showRealValues)
                    .toggleStyle(.button)
                    .font(AppTheme.Typography.caption())
                    .tint(AppTheme.Colors.growthGreen)
            }
            
            GrowthChartView(
                data: chartData,
                currency: currency,
                showRealValue: showRealValues,
                showDeposits: true,
                animateOnAppear: !hasLoaded
            )
            .onChange(of: chartData.count) { _, _ in
                hasLoaded = true
            }
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Milestone Previews
    
    private var milestonePreviews: some View {
        let milestones: [(Int, Color)] = [
            (10, AppTheme.Colors.neonBlue),
            (20, AppTheme.Colors.growthGreen),
            (30, AppTheme.Colors.goalGold)
        ]
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(milestones, id: \.0) { yr, color in
                    let fvAt = SavingsEngine.futureValue(
                        currentSavings: currentSavings,
                        monthlyDeposit: monthlyDeposit,
                        annualReturnRate: expectedReturn,
                        years: Double(yr)
                    )
                    let rvAt = SavingsEngine.realValue(
                        futureValue: fvAt,
                        annualInflationRate: inflationRate,
                        years: Double(yr)
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                            Text("\(yr) Years")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(color)
                        }
                        
                        Text(CurrencyHelper.formatCompact(fvAt, currency: currency))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text("Real: \(CurrencyHelper.formatCompact(rvAt, currency: currency))")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(width: 150)
                    .glassCard()
                }
            }
        }
    }
    
    // MARK: - Sliders Section
    
    private var slidersSection: some View {
        VStack(spacing: 20) {
            Text("Adjust Parameters")
                .font(AppTheme.Typography.subtitle())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Monthly Deposit
            parameterSlider(
                title: "Monthly Deposit",
                value: $monthlyDeposit,
                range: 0...10000,
                step: 50,
                format: { CurrencyHelper.format($0, currency: currency) },
                color: AppTheme.Colors.growthGreen,
                icon: "banknote.fill"
            )
            
            // Years
            parameterSlider(
                title: "Time Horizon",
                value: $years,
                range: 1...50,
                step: 1,
                format: { "\(Int($0)) years" },
                color: AppTheme.Colors.neonBlue,
                icon: "calendar"
            ) { oldVal, newVal in
                HapticManager.shared.checkYearMilestone(oldYears: oldVal, newYears: newVal)
            }
            
            // Expected Return
            parameterSlider(
                title: "Expected Annual Return",
                value: $expectedReturn,
                range: 0...20,
                step: 0.5,
                format: { String(format: "%.1f%%", $0) },
                color: AppTheme.Colors.purple,
                icon: "chart.line.uptrend.xyaxis"
            )
            
            // Inflation
            parameterSlider(
                title: "Inflation Rate",
                value: $inflationRate,
                range: 0...15,
                step: 0.5,
                format: { String(format: "%.1f%%", $0) },
                color: AppTheme.Colors.orange,
                icon: "flame.fill"
            )
            
            // Current Savings
            parameterSlider(
                title: "Current Savings",
                value: $currentSavings,
                range: 0...1_000_000,
                step: 1000,
                format: { CurrencyHelper.format($0, currency: currency) },
                color: AppTheme.Colors.goalGold,
                icon: "building.columns.fill"
            )
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Year-by-Year Table
    
    @State private var showFullTable = false
    
    private var yearByYearSection: some View {
        let rows = SavingsEngine.yearlyBreakdown(
            currentSavings: currentSavings,
            monthlyDeposit: monthlyDeposit,
            annualReturnRate: expectedReturn,
            annualInflationRate: inflationRate,
            totalYears: Int(years)
        )
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Year-by-Year Detail")
                    .font(AppTheme.Typography.subtitle())
                Spacer()
                Button(showFullTable ? "Show Less" : "Show All") {
                    withAnimation { showFullTable.toggle() }
                    HapticManager.shared.light()
                }
                .font(AppTheme.Typography.caption())
                .foregroundStyle(AppTheme.Colors.neonBlue)
            }
            
            // Header
            HStack(spacing: 0) {
                Text("Yr").frame(width: 30, alignment: .leading)
                Text("Balance").frame(maxWidth: .infinity, alignment: .trailing)
                Text("Interest").frame(maxWidth: .infinity, alignment: .trailing)
                Text("Daily $").frame(width: 65, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            
            let displayedRows = showFullTable ? rows : Array(rows.prefix(10))
            
            ForEach(displayedRows) { row in
                HStack(spacing: 0) {
                    Text("\(row.year)")
                        .frame(width: 30, alignment: .leading)
                        .foregroundStyle(.secondary)
                    
                    Text(CurrencyHelper.formatCompact(row.endBalance, currency: currency))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(AppTheme.Colors.neonBlue)
                    
                    Text(CurrencyHelper.formatCompact(row.interestThisYear, currency: currency))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(AppTheme.Colors.growthGreen)
                    
                    Text(CurrencyHelper.format(row.dailyEarnings, currency: currency))
                        .frame(width: 65, alignment: .trailing)
                        .foregroundStyle(AppTheme.Colors.goalGold)
                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                
                if row.year < displayedRows.last?.year ?? 0 {
                    Divider().opacity(0.3)
                }
            }
            
            if !showFullTable && rows.count > 10 {
                Text("\(rows.count - 10) more years...")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Breakdown Section
    
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breakdown")
                .font(AppTheme.Typography.subtitle())
            
            breakdownRow(label: "Total Deposited", value: totalDeposited, color: AppTheme.Colors.chartDeposits)
            breakdownRow(label: "Compound Interest", value: compoundInterest, color: AppTheme.Colors.neonBlue)
            breakdownRow(label: "Nominal Future Value", value: fv, color: .primary)
            
            Divider()
            
            breakdownRow(label: "Real Value (Today's \(currency))", value: rv, color: AppTheme.Colors.growthGreen)
            breakdownRow(label: "Purchasing Power Lost", value: fv - rv, color: AppTheme.Colors.alertRed)
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Components
    
    private func parameterSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: (Double) -> String,
        color: Color,
        icon: String,
        onChange: ((Double, Double) -> Void)? = nil
    ) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(title)
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Slider(value: value, in: range, step: step) {
                Text(title)
            } onEditingChanged: { editing in
                if editing { HapticManager.shared.selection() }
            }
            .tint(color)
            .onChange(of: value.wrappedValue) { oldVal, newVal in
                onChange?(oldVal, newVal)
                let newFV = SavingsEngine.futureValue(currentSavings: currentSavings, monthlyDeposit: monthlyDeposit, annualReturnRate: expectedReturn, years: years)
                // Use the slider delta direction to estimate old FV
                let delta = newVal - oldVal
                let oldFV = max(0, newFV - abs(delta) * 100)
                HapticManager.shared.checkMilestone(oldValue: oldFV, newValue: newFV)
            }
        }
    }
    
    private func breakdownRow(label: String, value: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
            Spacer()
            Text(CurrencyHelper.format(value, currency: currency))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
        }
    }
    
    // MARK: - Load from Goal
    
    private func loadFromGoal() {
        guard let goal = goal else { return }
        monthlyDeposit = goal.monthlyDeposit
        years = min(goal.yearsToTarget, 50)
        expectedReturn = goal.expectedReturn
        inflationRate = goal.inflationRate
        currentSavings = goal.currentSavings
        currency = goal.currency
    }
}

#Preview {
    NavigationStack {
        TimeMachineView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
