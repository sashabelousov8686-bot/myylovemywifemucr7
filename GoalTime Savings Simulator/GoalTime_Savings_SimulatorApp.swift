import SwiftUI

@main
struct GoalTime_Savings_SimulatorApp: App {
    let persistence = PersistenceController.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .preferredColorScheme(AppearanceMode(rawValue: appearanceMode)?.colorScheme)
        }
    }
}

// MARK: - Root View with Goal Guard

/// Ensures the user always has a goal before seeing the main app.
/// If onboarding completed but goal was deleted (e.g., via Reset), redirects back to onboarding.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoalEntity.createdAt, ascending: false)],
        animation: .default
    )
    private var allGoals: FetchedResults<SavingsGoalEntity>
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if allGoals.isEmpty {
                // Edge case: onboarding done but goal was deleted — send back
                OnboardingView()
                    .onAppear {
                        // Reset flag so onboarding runs cleanly
                        hasCompletedOnboarding = false
                    }
            } else {
                MainTabView()
            }
        }
    }
}
