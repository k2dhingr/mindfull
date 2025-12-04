import SwiftUI
import HealthKit

@main
struct MindfulHealthApp: App {
    @StateObject private var healthManager = HealthDataManager()
    @StateObject private var analyticsManager = HealthAnalyticsManager()
    @StateObject private var userProfile = UserProfile()
    @StateObject private var nutritionManager = NutritionManager()
    
    init() {
        // Configure appearance
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager)
                .environmentObject(analyticsManager)
                .environmentObject(userProfile)
                .environmentObject(nutritionManager)
                .preferredColorScheme(.dark)
        }
    }
    
    private func configureAppearance() {
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundColor = UIColor(red: 0.1, green: 0.15, blue: 0.2, alpha: 0.95)
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

