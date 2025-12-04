import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthDataManager
    @EnvironmentObject var userProfile: UserProfile
    @State private var isAnimating = false
    @State private var showApp = false
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if showApp && healthManager.isAuthorized {
                if userProfile.isProfileComplete {
                    MainTabView()
                } else {
                    OnboardingView(showOnboarding: $showOnboarding)
                        .onDisappear {
                            showOnboarding = false
                        }
                }
            } else {
                welcomeScreen
            }
        }
        .onAppear {
            // Check if profile exists
            if !userProfile.name.isEmpty && userProfile.age > 0 {
                showApp = true
            }
        }
    }
    
    var welcomeScreen: some View {
        ZStack {
            AnimatedBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("MindFull")
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Your AI-powered wellness companion")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
                
                VStack(spacing: 24) {
                    Text("We analyze your health patterns with privacy-first, on-device AI to provide personalized wellness insights.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            healthManager.checkAuthorization()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showApp = true
                                if userProfile.name.isEmpty {
                                    showOnboarding = true
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 20))
                            Text("Connect HealthKit")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.8, blue: 0.7),
                                    Color(red: 0.2, green: 0.7, blue: 0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 0.3, green: 0.8, blue: 0.7).opacity(0.5), radius: 20, y: 10)
                    }
                    .padding(.horizontal, 32)
                    
                    Text("All data stays on your device")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer() // Extra spacer to prevent button from being hidden
            }
            .padding(.bottom, 40) // Additional bottom padding
        }
        .ignoresSafeArea()
    }
}

struct AnimatedBackground: View {
    @State private var start = UnitPoint(x: 0, y: 0)
    @State private var end = UnitPoint(x: 1, y: 1)
    
    let colors = [
        Color(red: 0.1, green: 0.2, blue: 0.3),
        Color(red: 0.2, green: 0.3, blue: 0.4),
        Color(red: 0.15, green: 0.35, blue: 0.45),
        Color(red: 0.1, green: 0.25, blue: 0.35)
    ]
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: start,
            endPoint: end
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                start = UnitPoint(x: 1, y: 0)
                end = UnitPoint(x: 0, y: 1)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthDataManager())
        .environmentObject(UserProfile())
}
