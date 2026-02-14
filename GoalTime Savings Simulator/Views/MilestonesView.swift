import SwiftUI
import CoreData

// MARK: - Life Milestones Timeline

struct MilestonesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoalEntity.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isPrimary == YES"),
        animation: .default
    )
    private var primaryGoals: FetchedResults<SavingsGoalEntity>
    
    @AppStorage("selectedCurrency") private var currency = "USD"
    @State private var showAddMilestone = false
    
    private var goal: SavingsGoalEntity? { primaryGoals.first }
    
    private var milestones: [YearMilestone] {
        guard let goal = goal else { return [] }
        return SavingsEngine.yearlyMilestones(
            currentSavings: goal.currentSavings,
            monthlyDeposit: goal.monthlyDeposit,
            annualReturnRate: goal.expectedReturn,
            annualInflationRate: goal.inflationRate,
            targetAmount: goal.targetAmount,
            startYear: Calendar.current.component(.year, from: Date()),
            totalYears: min(Int(goal.yearsToTarget) + 10, 50)
        )
    }
    
    // Filter to show only every 5 years + goal reached year
    private var displayedMilestones: [YearMilestone] {
        var result: [YearMilestone] = []
        var goalReachedAdded = false
        
        for milestone in milestones {
            if milestone.yearsFromNow % 5 == 0 || milestone.yearsFromNow == 0 {
                result.append(milestone)
            }
            
            if milestone.goalReached && !goalReachedAdded && milestone.yearsFromNow % 5 != 0 {
                result.append(milestone)
                goalReachedAdded = true
            }
        }
        
        return result.sorted { $0.yearsFromNow < $1.yearsFromNow }
    }
    
    private var userAge: Int { Int(goal?.userAge ?? 30) }
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    headerCard
                    
                    // Timeline
                    timelineView
                    
                    // Custom milestones from Core Data
                    if let goal = goal, !goal.milestonesArray.isEmpty {
                        customMilestonesSection(goal)
                    }
                    
                    DisclaimerBanner()
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Life Milestones")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if goal != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMilestone = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppTheme.Colors.neonBlue)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddMilestone) {
            if let goal = goal {
                AddMilestoneSheet(goal: goal)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.goalGold)
                .glow(AppTheme.Colors.goalGold, radius: 10)
            
            Text("Your Financial Timeline")
                .font(AppTheme.Typography.title(22))
            
            if let goal = goal {
                Text("See when you'll reach your milestones based on current parameters.")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    miniInfo("Goal", CurrencyHelper.formatCompact(goal.targetAmount, currency: goal.currency))
                    miniInfo("Monthly", CurrencyHelper.formatCompact(goal.monthlyDeposit, currency: goal.currency))
                    miniInfo("Return", String(format: "%.1f%%", goal.expectedReturn))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
    
    private func miniInfo(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.Colors.neonBlue)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Timeline
    
    private var timelineView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(displayedMilestones.enumerated()), id: \.element.id) { index, milestone in
                HStack(alignment: .top, spacing: 16) {
                    // Timeline line & dot
                    VStack(spacing: 0) {
                        Circle()
                            .fill(milestone.goalReached && milestone.progress >= 1.0 ? AppTheme.Colors.growthGreen : AppTheme.Colors.neonBlue)
                            .frame(width: 14, height: 14)
                            .overlay {
                                if milestone.goalReached && milestone.progress >= 1.0 {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .glow(milestone.goalReached ? AppTheme.Colors.growthGreen : AppTheme.Colors.neonBlue, radius: 4)
                        
                        if index < displayedMilestones.count - 1 {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.neonBlue.opacity(0.5), AppTheme.Colors.neonBlue.opacity(0.1)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .frame(width: 2, height: 80)
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(milestone.year)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Text("Age \(userAge + milestone.yearsFromNow)")
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.gray.opacity(0.15))
                                .clipShape(Capsule())
                            
                            if milestone.yearsFromNow == 0 {
                                Text("NOW")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.Colors.neonBlue)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Balance")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Text(CurrencyHelper.formatCompact(milestone.balance, currency: currency))
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.Colors.neonBlue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Real Value")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Text(CurrencyHelper.formatCompact(milestone.realBalance, currency: currency))
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.Colors.growthGreen)
                            }
                        }
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(milestone.progress >= 1.0 ? AppTheme.Colors.growthGreen : AppTheme.Colors.neonBlue)
                                    .frame(width: geo.size.width * CGFloat(milestone.progress), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        if milestone.goalReached && milestone.progress >= 1.0 {
                            Text("Goal Reached!")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.growthGreen)
                        }
                    }
                    .padding(.bottom, 12)
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Custom Milestones
    
    @ViewBuilder
    private func customMilestonesSection(_ goal: SavingsGoalEntity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Custom Milestones")
                .font(AppTheme.Typography.subtitle())
            
            ForEach(goal.milestonesArray) { milestone in
                HStack(spacing: 12) {
                    Image(systemName: milestone.icon)
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.goalGold)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.Colors.goalGold.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(milestone.name)
                            .font(.system(size: 14, weight: .semibold))
                        Text("Age \(milestone.targetAge) • \(CurrencyHelper.format(milestone.targetAmount, currency: currency))")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
            }
        }
        .padding(20)
        .glassCard()
    }
}

// MARK: - Add Milestone Sheet

struct AddMilestoneSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let goal: SavingsGoalEntity
    
    @State private var name = ""
    @State private var targetAge: Double = 35
    @State private var targetAmount = ""
    @State private var selectedIcon = "star.fill"
    
    private let icons = ["star.fill", "house.fill", "car.fill", "airplane", "graduationcap.fill", "heart.fill", "gift.fill", "briefcase.fill"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        TextField("Milestone name", text: $name)
                            .textFieldStyle(PremiumTextFieldStyle())
                        
                        TextField("Target amount", text: $targetAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(PremiumTextFieldStyle())
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Target Age")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(targetAge))")
                                    .foregroundStyle(AppTheme.Colors.neonBlue)
                                    .fontWeight(.semibold)
                            }
                            Slider(value: $targetAge, in: 18...90, step: 1)
                                .tint(AppTheme.Colors.neonBlue)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .foregroundStyle(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                ForEach(icons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                        HapticManager.shared.light()
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .foregroundStyle(selectedIcon == icon ? AppTheme.Colors.goalGold : .secondary)
                                            .frame(width: 48, height: 48)
                                            .background(selectedIcon == icon ? AppTheme.Colors.goalGold.opacity(0.15) : Color.gray.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveMilestone()
                        dismiss()
                    }
                    .disabled(name.isEmpty || (Double(targetAmount) ?? 0) <= 0)
                }
            }
        }
    }
    
    private func saveMilestone() {
        let ms = MilestoneEntity(context: viewContext)
        ms.id = UUID()
        ms.name = name
        ms.targetAge = Int32(targetAge)
        ms.targetAmount = Double(targetAmount) ?? 0
        ms.icon = selectedIcon
        ms.goal = goal
        PersistenceController.shared.save()
        HapticManager.shared.success()
    }
}

#Preview {
    NavigationStack {
        MilestonesView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
