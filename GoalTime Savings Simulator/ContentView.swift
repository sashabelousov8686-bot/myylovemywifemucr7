import SwiftUI

// MARK: - Main Tab Navigation

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MyGoalView()
            }
            .tabItem {
                Label("My Goal", systemImage: "target")
            }
            .tag(0)
            
            NavigationStack {
                TimeMachineView()
            }
            .tabItem {
                Label("Time Machine", systemImage: "clock.arrow.2.circlepath")
            }
            .tag(1)
            
            NavigationStack {
                IncrementalImpactView()
            }
            .tabItem {
                Label("Impact", systemImage: "plus.circle.fill")
            }
            .tag(2)
            
            NavigationStack {
                ParallelUniversesView()
            }
            .tabItem {
                Label("Universes", systemImage: "arrow.triangle.branch")
            }
            .tag(3)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .tint(AppTheme.Colors.neonBlue)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
