import SwiftUI

// MARK: - Onboarding Flow (4 Steps)

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedCurrency") private var selectedCurrency = "USD"
    
    @State private var currentStep = 0
    @State private var goalName = ""
    @State private var targetAmount = ""
    @State private var monthlyDeposit = ""
    @State private var expectedReturn = 7.0
    @State private var inflationRate = 3.0
    @State private var userAge = 30.0
    
    private let totalSteps = 4
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(step <= currentStep ? AppTheme.Colors.neonBlue : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Step content
                TabView(selection: $currentStep) {
                    stepGoal.tag(0)
                    stepDeposit.tag(1)
                    stepReturn.tag(2)
                    stepInflation.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentStep)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button {
                            HapticManager.shared.light()
                            currentStep -= 1
                        } label: {
                            Text("Back")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(height: 56)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                        }
                    }
                    
                    Button {
                        HapticManager.shared.medium()
                        if currentStep < totalSteps - 1 {
                            currentStep += 1
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentStep == totalSteps - 1 ? "Start Simulation" : "Continue")
                    }
                    .buttonStyle(PremiumButtonStyle(gradient: AppTheme.neonBlueGradient))
                    .disabled(!isStepValid)
                    .opacity(isStepValid ? 1 : 0.5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                DisclaimerBanner()
                    .padding(.bottom, 8)
            }
        }
    }
    
    // MARK: - Step 1: Goal
    
    private var stepGoal: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.Colors.goalGold)
                .glow(AppTheme.Colors.goalGold, radius: 12)
            
            Text("What's Your Goal?")
                .font(AppTheme.Typography.title(28))
                .foregroundStyle(.primary)
            
            Text("Name your savings goal and set a target amount.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                TextField("Goal name (e.g., Dream Home)", text: $goalName)
                    .textFieldStyle(PremiumTextFieldStyle())
                
                TextField("Target amount", text: $targetAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PremiumTextFieldStyle())
                
                HStack {
                    Text("Your Age")
                        .font(AppTheme.Typography.subtitle())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(userAge))")
                        .font(AppTheme.Typography.subtitle())
                        .foregroundStyle(AppTheme.Colors.neonBlue)
                }
                .padding(.horizontal, 4)
                
                Slider(value: $userAge, in: 18...80, step: 1)
                    .tint(AppTheme.Colors.neonBlue)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Step 2: Monthly Deposit
    
    private var stepDeposit: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "banknote.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.Colors.growthGreen)
                .glow(AppTheme.Colors.growthGreen, radius: 12)
            
            Text("Monthly Contribution")
                .font(AppTheme.Typography.title(28))
                .foregroundStyle(.primary)
            
            Text("How much can you save each month?")
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                TextField("Monthly deposit amount", text: $monthlyDeposit)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PremiumTextFieldStyle())
                
                // Quick presets
                let sym = CurrencyManager.currency(for: selectedCurrency)?.symbol ?? "$"
                HStack(spacing: 12) {
                    ForEach(["100", "300", "500", "1000"], id: \.self) { amount in
                        Button {
                            monthlyDeposit = amount
                            HapticManager.shared.light()
                        } label: {
                            Text("\(sym)\(amount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(monthlyDeposit == amount ? .white : AppTheme.Colors.neonBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    monthlyDeposit == amount
                                    ? AnyShapeStyle(AppTheme.neonBlueGradient)
                                    : AnyShapeStyle(Color.gray.opacity(0.15))
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Step 3: Expected Return
    
    private var stepReturn: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.Colors.neonBlue)
                .glow(AppTheme.Colors.neonBlue, radius: 12)
            
            Text("Expected Annual Return")
                .font(AppTheme.Typography.title(28))
                .foregroundStyle(.primary)
            
            Text("What annual return do you expect on your savings?")
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 20) {
                Text("\(expectedReturn, specifier: "%.1f")%")
                    .font(AppTheme.Typography.heroNumber(48))
                    .foregroundStyle(AppTheme.Colors.neonBlue)
                    .contentTransition(.numericText(value: expectedReturn))
                    .animation(.easeInOut, value: expectedReturn)
                
                Slider(value: $expectedReturn, in: 0...20, step: 0.5) {
                    Text("Return Rate")
                } onEditingChanged: { editing in
                    if editing { HapticManager.shared.selection() }
                }
                .tint(AppTheme.Colors.neonBlue)
                .padding(.horizontal, 24)
                
                HStack {
                    strategyPill("Conservative", "1-3%", expectedReturn >= 1 && expectedReturn <= 3)
                    strategyPill("Moderate", "4-7%", expectedReturn >= 4 && expectedReturn <= 7)
                    strategyPill("Aggressive", "8-12%", expectedReturn >= 8 && expectedReturn <= 12)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Step 4: Inflation
    
    private var stepInflation: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.Colors.orange)
                .glow(AppTheme.Colors.orange, radius: 12)
            
            Text("Expected Inflation")
                .font(AppTheme.Typography.title(28))
                .foregroundStyle(.primary)
            
            Text("Account for the rising cost of living over time.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 20) {
                Text("\(inflationRate, specifier: "%.1f")%")
                    .font(AppTheme.Typography.heroNumber(48))
                    .foregroundStyle(AppTheme.Colors.orange)
                    .contentTransition(.numericText(value: inflationRate))
                    .animation(.easeInOut, value: inflationRate)
                
                Slider(value: $inflationRate, in: 0...15, step: 0.5) {
                    Text("Inflation Rate")
                } onEditingChanged: { editing in
                    if editing { HapticManager.shared.selection() }
                }
                .tint(AppTheme.Colors.orange)
                .padding(.horizontal, 24)
                
                Text("Historical average: 2-3% (developed markets)")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func strategyPill(_ name: String, _ range: String, _ isActive: Bool) -> some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.system(size: 11, weight: .semibold))
            Text(range)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isActive ? AppTheme.Colors.neonBlue.opacity(0.15) : Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? AppTheme.Colors.neonBlue.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0:
            return !goalName.isEmpty && (Double(targetAmount) ?? 0) > 0
        case 1:
            return (Double(monthlyDeposit) ?? 0) > 0
        default:
            return true
        }
    }
    
    private func completeOnboarding() {
        let target = Double(targetAmount) ?? 0
        let deposit = Double(monthlyDeposit) ?? 0
        
        // Calculate target date based on required time
        let months = SavingsEngine.monthsToGoal(
            currentSavings: 0,
            monthlyDeposit: deposit,
            annualReturnRate: expectedReturn,
            targetAmount: target
        ) ?? 240
        
        let targetDate = Calendar.current.date(byAdding: .month, value: months, to: Date())
        
        let _ = PersistenceController.shared.createGoal(
            name: goalName,
            targetAmount: target,
            targetDate: targetDate,
            currentSavings: 0,
            monthlyDeposit: deposit,
            expectedReturn: expectedReturn,
            inflationRate: inflationRate,
            currency: selectedCurrency,
            isPrimary: true,
            userAge: Int(userAge)
        )
        
        HapticManager.shared.success()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Premium TextField Style

struct PremiumTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 17, weight: .medium))
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.07)
                          : Color.black.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
    }
}

#Preview {
    OnboardingView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
