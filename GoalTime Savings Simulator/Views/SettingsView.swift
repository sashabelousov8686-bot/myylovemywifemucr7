import SwiftUI

// MARK: - Settings & Export

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoalEntity.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isPrimary == YES"),
        animation: .default
    )
    private var primaryGoals: FetchedResults<SavingsGoalEntity>
    
    @AppStorage("selectedCurrency") private var selectedCurrency = "USD"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
    @State private var showCurrencyPicker = false
    @State private var isExporting = false
    @State private var showResetConfirm = false
    
    private var goal: SavingsGoalEntity? { primaryGoals.first }
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Appearance section
                    appearanceSection
                    
                    // Currency section
                    currencySection
                    
                    // Export section
                    exportSection
                    
                    // Navigation to sub-screens
                    navigationSection
                    
                    // Education & tools
                    educationSection
                    
                    // App info
                    appInfoSection
                    
                    // Reset
                    resetSection
                    
                    DisclaimerBanner()
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selectedCurrency: $selectedCurrency)
        }
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetApp()
            }
        } message: {
            Text("This will delete all your goals and settings. This action cannot be undone.")
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Appearance", icon: "paintbrush.fill", color: AppTheme.Colors.purple)
            
            HStack(spacing: 10) {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appearanceMode = mode.rawValue
                        }
                        HapticManager.shared.light()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.title3)
                            Text(mode.label)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(appearanceMode == mode.rawValue ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            appearanceMode == mode.rawValue
                            ? AnyShapeStyle(AppTheme.Colors.purple.gradient)
                            : AnyShapeStyle(Color.gray.opacity(0.1))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                    }
                    .accessibilityLabel("\(mode.label) theme")
                    .accessibilityAddTraits(appearanceMode == mode.rawValue ? .isSelected : [])
                }
            }
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Currency Section
    
    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Currency", icon: "dollarsign.circle.fill", color: AppTheme.Colors.goalGold)
            
            Button {
                showCurrencyPicker = true
                HapticManager.shared.light()
            } label: {
                HStack {
                    if let info = CurrencyManager.currency(for: selectedCurrency) {
                        Text(info.flag)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(info.code)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(info.name)
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(selectedCurrency)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(Color.gray.opacity(0.08))
                )
            }
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Export", icon: "square.and.arrow.up.fill", color: AppTheme.Colors.growthGreen)
            
            Button {
                exportPDF()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.growthGreen)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export as PDF")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Generate a detailed projection report")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if isExporting {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(Color.gray.opacity(0.08))
                )
            }
            .disabled(goal == nil || isExporting)
            .opacity(goal == nil ? 0.5 : 1)
            
            if goal == nil {
                Text("Create a goal first to export a report.")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Navigation to Sub-screens
    
    private var navigationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Tools", icon: "wrench.and.screwdriver.fill", color: AppTheme.Colors.orange)
            
            NavigationLink {
                InflationAdjusterView()
            } label: {
                navRow(icon: "flame.fill", title: "Inflation Adjuster", subtitle: "See how inflation affects your goals", color: AppTheme.Colors.orange)
            }
            
            NavigationLink {
                StrategyPresetsView()
            } label: {
                navRow(icon: "chart.bar.fill", title: "Strategy Presets", subtitle: "Conservative / Moderate / Aggressive", color: AppTheme.Colors.neonBlue)
            }
            
            NavigationLink {
                MilestonesView()
            } label: {
                navRow(icon: "flag.checkered", title: "Life Milestones", subtitle: "Your financial timeline", color: AppTheme.Colors.goalGold)
            }
        }
        .padding(20)
        .glassCard()
    }
    
    private func navRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Education & Tools
    
    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Learn & Explore", icon: "book.fill", color: AppTheme.Colors.neonBlue)
            
            NavigationLink {
                LearnView()
            } label: {
                navRow(icon: "books.vertical.fill", title: "Financial Concepts", subtitle: "Compound interest, inflation, and more", color: AppTheme.Colors.neonBlue)
            }
            
            NavigationLink {
                QuickToolsView()
            } label: {
                navRow(icon: "wrench.and.screwdriver.fill", title: "Quick Tools", subtitle: "Rule of 72, Savings Rate, Inflation Erosion", color: AppTheme.Colors.growthGreen)
            }
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - App Info
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("About", icon: "info.circle.fill", color: .secondary)
            
            HStack {
                Text("Version")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.primary)
            }
            .font(AppTheme.Typography.body())
            
            HStack {
                Text("Data Storage")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("On-device only")
                    .foregroundStyle(AppTheme.Colors.growthGreen)
            }
            .font(AppTheme.Typography.body())
            
            HStack {
                Text("Network")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("100% Offline")
                    .foregroundStyle(AppTheme.Colors.growthGreen)
            }
            .font(AppTheme.Typography.body())
            
            HStack {
                Text("Data Collection")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("None")
                    .foregroundStyle(AppTheme.Colors.growthGreen)
            }
            .font(AppTheme.Typography.body())
        }
        .padding(20)
        .glassCard()
    }
    
    // MARK: - Reset
    
    private var resetSection: some View {
        VStack(spacing: 12) {
            Button {
                showResetConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Reset All Data")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.Colors.alertRed)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppTheme.Colors.alertRed.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
            }
        }
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(AppTheme.Typography.subtitle())
        }
    }
    
    private func exportPDF() {
        guard let goal = goal else { return }
        isExporting = true
        
        let chartData = SavingsEngine.growthCurve(
            currentSavings: goal.currentSavings,
            monthlyDeposit: goal.monthlyDeposit,
            annualReturnRate: goal.expectedReturn,
            annualInflationRate: goal.inflationRate,
            totalYears: min(Int(goal.yearsToTarget) + 5, 40)
        )
        
        Task { @MainActor in
            if let pdfData = PDFExportService.generateReport(
                goalName: goal.name,
                targetAmount: goal.targetAmount,
                currentSavings: goal.currentSavings,
                monthlyDeposit: goal.monthlyDeposit,
                expectedReturn: goal.expectedReturn,
                inflationRate: goal.inflationRate,
                currency: goal.currency,
                years: Int(goal.yearsToTarget),
                chartData: chartData
            ) {
                // Small delay to ensure any existing presentations are settled
                try? await Task.sleep(for: .milliseconds(100))
                PDFExportService.sharePDF(data: pdfData)
            }
            isExporting = false
        }
    }
    
    private func resetApp() {
        // Delete all goals
        let goals = PersistenceController.shared.fetchAllGoals()
        for goal in goals {
            PersistenceController.shared.deleteGoal(goal)
        }
        
        // Reset onboarding
        hasCompletedOnboarding = false
        
        HapticManager.shared.warning()
    }
}

// MARK: - Currency Picker Sheet

struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCurrency: String
    @State private var searchText = ""
    
    private var filteredCurrencies: [CurrencyInfo] {
        if searchText.isEmpty {
            return CurrencyManager.currencies
        }
        return CurrencyManager.currencies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBackground()
                
                List(filteredCurrencies) { currency in
                    Button {
                        selectedCurrency = currency.code
                        // Update existing goals
                        let goals = PersistenceController.shared.fetchAllGoals()
                        for goal in goals {
                            goal.currency = currency.code
                        }
                        PersistenceController.shared.save()
                        HapticManager.shared.light()
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text(currency.flag)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currency.code)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(currency.name)
                                    .font(AppTheme.Typography.caption())
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(currency.symbol)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            if selectedCurrency == currency.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.Colors.neonBlue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search currencies")
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
