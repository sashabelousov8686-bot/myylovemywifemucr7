import SwiftUI

// MARK: - Reusable "No Goal" Empty State

struct NoGoalView: View {
    let title: String
    let subtitle: String
    let onCreateGoal: () -> Void
    
    init(
        title: String = "No Goal Yet",
        subtitle: String = "Create a savings goal to unlock this feature.",
        onCreateGoal: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onCreateGoal = onCreateGoal
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.neonBlue.opacity(0.08))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "target")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.Colors.neonBlue.opacity(0.6))
            }
            
            Text(title)
                .font(AppTheme.Typography.title(22))
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(AppTheme.Typography.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                onCreateGoal()
                HapticManager.shared.medium()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Goal")
                }
            }
            .buttonStyle(PremiumButtonStyle(gradient: AppTheme.neonBlueGradient))
            .padding(.horizontal, 40)
            
            DisclaimerBanner()
            
            Spacer()
        }
    }
}
