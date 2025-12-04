import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var healthManager: HealthDataManager
    @EnvironmentObject var analyticsManager: HealthAnalyticsManager
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var nutritionManager: NutritionManager
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Dashboard")
                }
                .tag(0)
            
            NutritionView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Nutrition")
                }
                .tag(1)
            
            ChatView()
            .tabItem {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                Text("AI Coach")
            }
            .tag(2)
            
            MindfulnessView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Mindful")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(Color(red: 0.4, green: 0.8, blue: 0.6))
    }
}

#Preview {
    MainTabView()
        .environmentObject(HealthDataManager())
        .environmentObject(HealthAnalyticsManager())
        .environmentObject(UserProfile())
        .environmentObject(NutritionManager())
}

