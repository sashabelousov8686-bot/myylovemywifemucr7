import SwiftUI
import Charts

// MARK: - Parallel Universes: Compare Two Scenarios Side-by-Side

struct ParallelUniversesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoalEntity.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isPrimary == YES"),
        animation: .default
    )
    private var primaryGoals: FetchedResults<SavingsGoalEntity>
    
    @AppStorage("selectedCurrency") private var currency = "USD"
    
    // Universe A parameters
    @State private var depositA: Double = 500
    @State private var returnA: Double = 7.0
    @State private var yearsA: Double = 20
    
    // Universe B parameters
    @State private var depositB: Double = 800
    @State private var returnB: Double = 10.0
    @State private var yearsB: Double = 20
    
    @State private var inflationRate: Double = 3.0
    @State private var currentSavings: Double = 0
    @State private var syncYears = true
    
    private var goal: SavingsGoalEntity? { primaryGoals.first }
    
    private var dataA: [GrowthPoint] {
        SavingsEngine.growthCurve(
            currentSavings: currentSavings,
            monthlyDeposit: depositA,
            annualReturnRate: returnA,
            annualInflationRate: inflationRate,
            totalYears: Int(yearsA)
        )
    }
    
    private var dataB: [GrowthPoint] {
        SavingsEngine.growthCurve(
            currentSavings: currentSavings,
            monthlyDeposit: depositB,
            annualReturnRate: returnB,
            annualInflationRate: inflationRate,
            totalYears: Int(yearsB)
        )
    }
    
    private var fvA: Double {
        SavingsEngine.futureValue(currentSavings: currentSavings, monthlyDeposit: depositA, annualReturnRate: returnA, years: yearsA)
    }
    
    private var fvB: Double {
        SavingsEngine.futureValue(currentSavings: currentSavings, monthlyDeposit: depositB, annualReturnRate: returnB, years: yearsB)
    }
    
    private var difference: Double { fvB - fvA }
    
    @State private var showCreateGoal = false
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            if goal == nil {
                NoGoalView(
                    title: "Explore Parallel Universes",
                    subtitle: "Create a savings goal to compare two alternate financial futures."
                ) {
                    showCreateGoal = true
                }
            } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    headerCard
                    
                    // Comparison chart
                    chartCard
                    
                    // Results comparison
                    resultsComparison
                    
                    // Universe A controls
                    universeControls(
                        label: "Universe A",
                        color: AppTheme.Colors.neonBlue,
                        icon: "a.circle.fill",
                        deposit: $depositA,
                        returnRate: $returnA,
                        years: $yearsA
                    )
                    
                    // Universe B controls
                    universeControls(
                        label: "Universe B",
                        color: AppTheme.Colors.purple,
                        icon: "b.circle.fill",
                        deposit: $depositB,
                        returnRate: $returnB,
                        years: $yearsB
                    )
                    
                    // Shared parameters
                    sharedParameters
                    
                    DisclaimerBanner()
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            } // end else
        }
        .navigationTitle("Parallel Universes")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadFromGoal() }
        .sheet(isPresented: $showCreateGoal) {
            EditGoalSheet(goal: nil)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    // MARK: - Header
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.purple)
                .glow(AppTheme.Colors.purple, radius: 10)
            
            Text("Compare Two Futures")
                .font(AppTheme.Typography.title(22))
            
            Text("Adjust parameters for each universe and see the difference compound interest makes.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
    
    // MARK: - Chart
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Growth Comparison")
                .font(AppTheme.Typography.subtitle())
            
            ComparisonChartView(
                dataA: dataA,
                dataB: dataB,
                labelA: "Universe A",
                labelB: "Universe B",
                currency: currency
            )
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Results
    
    private var resultsComparison: some View {
        HStack(spacing: 12) {
            // Universe A result
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "a.circle.fill")
                        .foregroundStyle(AppTheme.Colors.neonBlue)
                    Text("Universe A")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                
                Text(CurrencyHelper.formatCompact(fvA, currency: currency))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.neonBlue)
                
                Text("\(CurrencyHelper.format(depositA, currency: currency))/mo")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCard()
            
            // Difference
            VStack(spacing: 4) {
                Image(systemName: difference >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.title3)
                    .foregroundStyle(difference >= 0 ? AppTheme.Colors.growthGreen : AppTheme.Colors.alertRed)
                
                Text(difference >= 0 ? "+" : "")
                    .font(.system(size: 10)) +
                Text(CurrencyHelper.formatCompact(abs(difference), currency: currency))
                    .font(.system(size: 12, weight: .bold))
            }
            .frame(width: 60)
            
            // Universe B result
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "b.circle.fill")
                        .foregroundStyle(AppTheme.Colors.purple)
                    Text("Universe B")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                
                Text(CurrencyHelper.formatCompact(fvB, currency: currency))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.purple)
                
                Text("\(CurrencyHelper.format(depositB, currency: currency))/mo")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCard()
        }
    }
    
    // MARK: - Universe Controls
    
    private func universeControls(
        label: String,
        color: Color,
        icon: String,
        deposit: Binding<Double>,
        returnRate: Binding<Double>,
        years: Binding<Double>
    ) -> some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(AppTheme.Typography.subtitle())
                Spacer()
            }
            
            // Deposit
            sliderControl(
                title: "Monthly Deposit",
                value: deposit,
                range: 0...10000,
                step: 50,
                format: { CurrencyHelper.format($0, currency: currency) },
                color: color
            )
            
            // Return
            sliderControl(
                title: "Annual Return",
                value: returnRate,
                range: 0...20,
                step: 0.5,
                format: { String(format: "%.1f%%", $0) },
                color: color
            )
            
            // Years
            sliderControl(
                title: "Years",
                value: years,
                range: 1...50,
                step: 1,
                format: { "\(Int($0)) years" },
                color: color
            )
            .onChange(of: years.wrappedValue) { _, newVal in
                if syncYears {
                    if label == "Universe A" { yearsB = newVal }
                    else { yearsA = newVal }
                }
            }
        }
        .padding(20)
        .glassCard()
    }
    
    private func sliderControl(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: (Double) -> String,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }
            Slider(value: value, in: range, step: step) {
                Text(title)
            } onEditingChanged: { editing in
                if editing { HapticManager.shared.selection() }
            }
            .tint(color)
        }
    }
    
    // MARK: - Shared Parameters
    
    private var sharedParameters: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                Text("Shared Parameters")
                    .font(AppTheme.Typography.subtitle())
                Spacer()
                
                Toggle("Sync Years", isOn: $syncYears)
                    .toggleStyle(.button)
                    .font(AppTheme.Typography.caption())
                    .tint(AppTheme.Colors.neonBlue)
            }
            
            sliderControl(
                title: "Current Savings",
                value: $currentSavings,
                range: 0...1_000_000,
                step: 1000,
                format: { CurrencyHelper.format($0, currency: currency) },
                color: AppTheme.Colors.goalGold
            )
            
            sliderControl(
                title: "Inflation Rate",
                value: $inflationRate,
                range: 0...15,
                step: 0.5,
                format: { String(format: "%.1f%%", $0) },
                color: AppTheme.Colors.orange
            )
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Load from Goal
    
    private func loadFromGoal() {
        guard let goal = goal else { return }
        depositA = goal.monthlyDeposit
        returnA = goal.expectedReturn
        yearsA = min(goal.yearsToTarget, 50)
        inflationRate = goal.inflationRate
        currentSavings = goal.currentSavings
        
        // Universe B: slightly more aggressive
        depositB = goal.monthlyDeposit * 1.5
        returnB = min(goal.expectedReturn + 3, 20)
        yearsB = yearsA
    }
}

#Preview {
    NavigationStack {
        ParallelUniversesView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
