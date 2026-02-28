import SwiftUI
import Charts

// MARK: - My Goal (Primary Goal Dashboard)

struct MyGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoalEntity.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isPrimary == YES"),
        animation: .default
    )
    private var primaryGoals: FetchedResults<SavingsGoalEntity>
    
    @State private var showEditGoal = false
    @State private var showTimeMachine = false
    @State private var animateProgress = false
    
    private var goal: SavingsGoalEntity? { primaryGoals.first }
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    if let goal = goal {
                        goalContent(goal)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("My Goal")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditGoal = true
                } label: {
                    Image(systemName: goal == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.neonBlue)
                }
            }
        }
        .sheet(isPresented: $showEditGoal) {
            EditGoalSheet(goal: goal)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showTimeMachine) {
            NavigationStack {
                TimeMachineView()
            }
        }
    }
    
    // MARK: - Goal Content
    
    @ViewBuilder
    private func goalContent(_ goal: SavingsGoalEntity) -> some View {
        // Hero card with progress
        VStack(spacing: 20) {
            // Goal icon & name
            VStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.Colors.goalGold)
                    .glow(AppTheme.Colors.goalGold, radius: 10)
                
                Text(goal.name)
                    .font(AppTheme.Typography.title(22))
                    .foregroundStyle(.primary)
            }
            
            // Progress ring with amount
            ZStack {
                ProgressRing(
                    progress: animateProgress ? currentProgress(goal) : 0,
                    lineWidth: 14,
                    size: 180
                )
                
                VStack(spacing: 4) {
                    AnimatedCounter(
                        value: currentFutureValue(goal),
                        currency: goal.currency,
                        font: AppTheme.Typography.heroNumber(28),
                        color: AppTheme.Colors.neonBlue
                    )
                    
                    Text("of \(CurrencyHelper.format(goal.targetAmount, currency: goal.currency))")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(currentProgress(goal) * 100))%")
                        .font(AppTheme.Typography.subtitle())
                        .foregroundStyle(AppTheme.Colors.growthGreen)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                    animateProgress = true
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Progress: \(Int(currentProgress(goal) * 100)) percent of \(CurrencyHelper.format(goal.targetAmount, currency: goal.currency)) goal")
            
            // Time remaining
            if let targetDate = goal.targetDate {
                let remaining = remainingTime(to: targetDate)
                HStack(spacing: 20) {
                    timeBlock(value: remaining.years, label: "Years")
                    timeBlock(value: remaining.months, label: "Months")
                }
            }
            
            // Required monthly deposit info
            let required = SavingsEngine.requiredMonthlyDeposit(
                currentSavings: goal.currentSavings,
                targetAmount: goal.targetAmount,
                annualReturnRate: goal.expectedReturn,
                years: goal.yearsToTarget
            )
            
            if required > goal.monthlyDeposit {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppTheme.Colors.orange)
                    Text("Need \(CurrencyHelper.format(required, currency: goal.currency))/mo to reach goal on time")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.Colors.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
            }
        }
        .padding(24)
        .glassCard()
        
        // Quick stats grid
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(
                title: "Monthly Deposit",
                value: CurrencyHelper.format(goal.monthlyDeposit, currency: goal.currency),
                icon: "arrow.up.circle.fill",
                color: AppTheme.Colors.growthGreen
            )
            
            statCard(
                title: "Expected Return",
                value: String(format: "%.1f%%", goal.expectedReturn),
                icon: "chart.line.uptrend.xyaxis",
                color: AppTheme.Colors.neonBlue
            )
            
            let fv10 = SavingsEngine.futureValue(
                currentSavings: goal.currentSavings,
                monthlyDeposit: goal.monthlyDeposit,
                annualReturnRate: goal.expectedReturn,
                years: 10
            )
            statCard(
                title: "In 10 Years",
                value: CurrencyHelper.formatCompact(fv10, currency: goal.currency),
                icon: "clock.fill",
                color: AppTheme.Colors.purple
            )
            
            let fv30 = SavingsEngine.futureValue(
                currentSavings: goal.currentSavings,
                monthlyDeposit: goal.monthlyDeposit,
                annualReturnRate: goal.expectedReturn,
                years: 30
            )
            statCard(
                title: "In 30 Years",
                value: CurrencyHelper.formatCompact(fv30, currency: goal.currency),
                icon: "sparkles",
                color: AppTheme.Colors.goalGold
            )
        }
        
        // MARK: Savings Health Score
        healthScoreCard(goal)
        
        // MARK: Goal Achievability
        achievabilityCard(goal)
        
        // MARK: Your Money Never Sleeps
        moneyNeverSleepsCard(goal)
        
        // MARK: Personalized Insights
        insightsSection(goal)
        
        // Mini chart
        let chartData = SavingsEngine.growthCurve(
            currentSavings: goal.currentSavings,
            monthlyDeposit: goal.monthlyDeposit,
            annualReturnRate: goal.expectedReturn,
            annualInflationRate: goal.inflationRate,
            totalYears: min(Int(goal.yearsToTarget) + 5, 40)
        )
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Growth Projection")
                .font(AppTheme.Typography.subtitle())
                .foregroundStyle(.primary)
            
            GrowthChartView(
                data: chartData,
                currency: goal.currency,
                showRealValue: true,
                showDeposits: true
            )
        }
        .padding(20)
        .glassCard()
        
        // Time Machine button
        Button {
            showTimeMachine = true
            HapticManager.shared.medium()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.title3)
                Text("Open Time Machine")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(AppTheme.neonBlueGradient)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
        }
        
        DisclaimerBanner()
    }
    
    // MARK: - Savings Health Score Card
    
    private func healthScoreCard(_ goal: SavingsGoalEntity) -> some View {
        let report = SavingsEngine.healthScore(
            currentSavings: goal.currentSavings,
            monthlyDeposit: goal.monthlyDeposit,
            targetAmount: goal.targetAmount,
            annualReturnRate: goal.expectedReturn,
            annualInflationRate: goal.inflationRate,
            yearsToTarget: goal.yearsToTarget
        )
        
        let scoreColor: Color = switch report.status {
        case .excellent: AppTheme.Colors.growthGreen
        case .good: AppTheme.Colors.neonBlue
        case .fair: AppTheme.Colors.goalGold
        case .atRisk: AppTheme.Colors.orange
        case .critical: AppTheme.Colors.alertRed
        }
        
        return VStack(spacing: 16) {
            HStack {
                Image(systemName: report.status.icon)
                    .font(.title2)
                    .foregroundStyle(scoreColor)
                
                Text("Savings Health Score")
                    .font(AppTheme.Typography.subtitle())
                
                Spacer()
                
                Text(report.status.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(scoreColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            // Score circle
            HStack(spacing: 20) {
                ZStack {
                    ProgressRing(
                        progress: report.overall / 100.0,
                        lineWidth: 8,
                        gradient: LinearGradient(colors: [scoreColor, scoreColor.opacity(0.6)], startPoint: .top, endPoint: .bottom),
                        size: 80
                    )
                    
                    Text("\(Int(report.overall))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                }
                
                // Factor breakdown
                VStack(alignment: .leading, spacing: 6) {
                    healthFactor("Funding", report.funding, 30, AppTheme.Colors.neonBlue)
                    healthFactor("Time Buffer", report.timeBuffer, 25, AppTheme.Colors.growthGreen)
                    healthFactor("Inflation Shield", report.inflationShield, 20, AppTheme.Colors.orange)
                    healthFactor("Compound Power", report.compoundPower, 25, AppTheme.Colors.purple)
                }
            }
            
            // Advice
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppTheme.Colors.goalGold)
                    .font(.caption)
                Text(report.advice)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(AppTheme.Colors.goalGold.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(20)
        .glassCard()
    }
    
    private func healthFactor(_ name: String, _ value: Double, _ maxVal: Double, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 95, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value / maxVal))
                }
            }
            .frame(height: 5)
            
            Text("\(Int(value))/\(Int(maxVal))")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
    }
    
    // MARK: - Goal Achievability Card
    
    private func achievabilityCard(_ goal: SavingsGoalEntity) -> some View {
        let result = SavingsEngine.achievabilityStatus(
            currentSavings: goal.currentSavings,
            monthlyDeposit: goal.monthlyDeposit,
            targetAmount: goal.targetAmount,
            annualReturnRate: goal.expectedReturn,
            yearsToTarget: goal.yearsToTarget
        )
        
        let statusColor: Color = switch result.status {
        case .aheadOfSchedule: AppTheme.Colors.growthGreen
        case .onTrack: AppTheme.Colors.neonBlue
        case .slightlyBehind: AppTheme.Colors.goalGold
        case .behind: AppTheme.Colors.orange
        case .significantlyBehind: AppTheme.Colors.alertRed
        }
        
        return HStack(spacing: 14) {
            Image(systemName: result.status.icon)
                .font(.system(size: 28))
                .foregroundStyle(statusColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.status.label)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(statusColor)
                
                Text(result.message)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(16)
        .glassCard()
    }
    
    // MARK: - Personalized Insights
    
    private func insightsSection(_ goal: SavingsGoalEntity) -> some View {
        let insights = SavingsEngine.generateInsights(
            currentSavings: goal.currentSavings,
            monthlyDeposit: goal.monthlyDeposit,
            targetAmount: goal.targetAmount,
            annualReturnRate: goal.expectedReturn,
            annualInflationRate: goal.inflationRate,
            yearsToTarget: goal.yearsToTarget,
            userAge: Int(goal.userAge)
        )
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.max.fill")
                    .foregroundStyle(AppTheme.Colors.goalGold)
                Text("Your Insights")
                    .font(AppTheme.Typography.subtitle())
                Spacer()
            }
            
            ForEach(Array(insights.prefix(3))) { insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insight.icon)
                        .font(.subheadline)
                        .foregroundStyle(insightColor(insight.color))
                        .frame(width: 28, height: 28)
                        .background(insightColor(insight.color).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(insight.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(insight.message)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(insight.title). \(insight.message)")
            }
        }
        .padding(20)
        .glassCard()
    }
    
    private func insightColor(_ name: String) -> Color {
        switch name {
        case "neonBlue": return AppTheme.Colors.neonBlue
        case "growthGreen": return AppTheme.Colors.growthGreen
        case "goalGold": return AppTheme.Colors.goalGold
        case "orange": return AppTheme.Colors.orange
        case "purple": return AppTheme.Colors.purple
        case "alertRed": return AppTheme.Colors.alertRed
        default: return AppTheme.Colors.neonBlue
        }
    }
    
    // MARK: - Your Money Never Sleeps
    
    private func moneyNeverSleepsCard(_ goal: SavingsGoalEntity) -> some View {
        let fv = currentFutureValue(goal)
        let dailyEarnings = SavingsEngine.dailyPassiveEarnings(
            currentBalance: fv,
            annualReturnRate: goal.expectedReturn
        )
        let hourlyEarnings = dailyEarnings / 24.0
        let monthlyPassive = dailyEarnings * 30.0
        
        return VStack(spacing: 14) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(AppTheme.Colors.purple)
                Text("Your Money Never Sleeps")
                    .font(AppTheme.Typography.subtitle())
                Spacer()
            }
            
            Text("At your projected balance, compound interest earns:")
                .font(AppTheme.Typography.caption())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                earningsBlock(
                    value: CurrencyHelper.format(hourlyEarnings, currency: goal.currency),
                    label: "Per Hour",
                    color: AppTheme.Colors.purple
                )
                earningsBlock(
                    value: CurrencyHelper.format(dailyEarnings, currency: goal.currency),
                    label: "Per Day",
                    color: AppTheme.Colors.neonBlue
                )
                earningsBlock(
                    value: CurrencyHelper.format(monthlyPassive, currency: goal.currency),
                    label: "Per Month",
                    color: AppTheme.Colors.growthGreen
                )
            }
            
            Text("Based on projected future balance of \(CurrencyHelper.formatCompact(fv, currency: goal.currency)) at \(String(format: "%.1f%%", goal.expectedReturn)) return. For educational simulation only.")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .glassCard()
    }
    
    private func earningsBlock(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            
            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.Colors.neonBlue.opacity(0.5))
            
            Text("No Goal Set Yet")
                .font(AppTheme.Typography.title())
                .foregroundStyle(.primary)
            
            Text("Tap + to create your first savings goal and start simulating your financial future.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            DisclaimerBanner()
        }
    }
    
    // MARK: - Components
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(AppTheme.Typography.caption())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
    
    private func timeBlock(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(AppTheme.Typography.heroNumber(32))
                .foregroundStyle(AppTheme.Colors.neonBlue)
            Text(label)
                .font(AppTheme.Typography.caption())
                .foregroundStyle(.secondary)
        }
    }
    
    private func currentFutureValue(_ goal: SavingsGoalEntity) -> Double {
        SavingsEngine.futureValue(
            currentSavings: goal.currentSavings,
            monthlyDeposit: goal.monthlyDeposit,
            annualReturnRate: goal.expectedReturn,
            years: goal.yearsToTarget
        )
    }
    
    private func currentProgress(_ goal: SavingsGoalEntity) -> Double {
        guard goal.targetAmount > 0 else { return 0 }
        let fv = currentFutureValue(goal)
        return min(fv / goal.targetAmount, 1.0)
    }
    
    private func remainingTime(to date: Date) -> (years: Int, months: Int) {
        let components = Calendar.current.dateComponents([.year, .month], from: Date(), to: date)
        return (max(0, components.year ?? 0), max(0, components.month ?? 0))
    }
}

// MARK: - Edit Goal Sheet

struct EditGoalSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedCurrency") private var selectedCurrency = "USD"
    
    let goal: SavingsGoalEntity?
    
    @State private var name = ""
    @State private var targetAmount = ""
    @State private var currentSavings = ""
    @State private var monthlyDeposit = ""
    @State private var expectedReturn = 7.0
    @State private var inflationRate = 3.0
    @State private var userAge = 30.0
    @State private var targetYears = 20.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBackground()
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Goal Details")
                                .font(AppTheme.Typography.subtitle())
                                .foregroundStyle(.secondary)
                            
                            TextField("Goal name", text: $name)
                                .textFieldStyle(PremiumTextFieldStyle())
                            
                            TextField("Target amount", text: $targetAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(PremiumTextFieldStyle())
                            
                            TextField("Current savings", text: $currentSavings)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(PremiumTextFieldStyle())
                            
                            TextField("Monthly deposit", text: $monthlyDeposit)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(PremiumTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Parameters")
                                .font(AppTheme.Typography.subtitle())
                                .foregroundStyle(.secondary)
                            
                            sliderRow(title: "Your Age", value: $userAge, range: 18...80, format: "%.0f")
                            sliderRow(title: "Target Years", value: $targetYears, range: 1...50, format: "%.0f")
                            sliderRow(title: "Expected Return %", value: $expectedReturn, range: 0...20, format: "%.1f%%")
                            sliderRow(title: "Inflation Rate %", value: $inflationRate, range: 0...15, format: "%.1f%%")
                        }
                        
                        DisclaimerBanner()
                    }
                    .padding(20)
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                        HapticManager.shared.success()
                        dismiss()
                    }
                    .disabled(name.isEmpty || (Double(targetAmount) ?? 0) <= 0)
                }
            }
            .onAppear { loadGoal() }
        }
    }
    
    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(AppTheme.Typography.subtitle())
                    .foregroundStyle(AppTheme.Colors.neonBlue)
            }
            Slider(value: value, in: range, step: format.contains("%%") ? 0.5 : 1)
                .tint(AppTheme.Colors.neonBlue)
        }
    }
    
    private func loadGoal() {
        guard let goal = goal else { return }
        name = goal.name
        targetAmount = String(format: "%.0f", goal.targetAmount)
        currentSavings = String(format: "%.0f", goal.currentSavings)
        monthlyDeposit = String(format: "%.0f", goal.monthlyDeposit)
        expectedReturn = goal.expectedReturn
        inflationRate = goal.inflationRate
        userAge = Double(goal.userAge)
        targetYears = goal.yearsToTarget
    }
    
    private func saveGoal() {
        let target = Double(targetAmount) ?? 0
        let savings = Double(currentSavings) ?? 0
        let deposit = Double(monthlyDeposit) ?? 0
        let targetDate = Calendar.current.date(byAdding: .year, value: Int(targetYears), to: Date())
        
        if let goal = goal {
            goal.name = name
            goal.targetAmount = target
            goal.currentSavings = savings
            goal.monthlyDeposit = deposit
            goal.expectedReturn = expectedReturn
            goal.inflationRate = inflationRate
            goal.targetDate = targetDate
            goal.userAge = Int32(userAge)
            PersistenceController.shared.save()
        } else {
            let _ = PersistenceController.shared.createGoal(
                name: name,
                targetAmount: target,
                targetDate: targetDate,
                currentSavings: savings,
                monthlyDeposit: deposit,
                expectedReturn: expectedReturn,
                inflationRate: inflationRate,
                currency: selectedCurrency,
                isPrimary: true,
                userAge: Int(userAge)
            )
        }
    }
}

#Preview {
    NavigationStack {
        MyGoalView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
