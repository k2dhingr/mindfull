import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var healthManager: HealthDataManager
    @EnvironmentObject var analyticsManager: HealthAnalyticsManager
    @EnvironmentObject var userProfile: UserProfile
    
    @State private var useDemoData = false
    @State private var isSyncing = false
    @State private var lastSyncTime: Date? = nil
    @State private var showPredictionInfo = false
    @State private var syncRotation: Double = 0
    
    // Demo data values - realistic for video demo
    private let demoSteps: Int = 8547
    private let demoSleep: Double = 7.2
    private let demoHeartRate: Double = 72
    private let demoRestingHR: Double = 58
    private let demoHRV: Double = 45
    private let demoCalories: Double = 423
    private let demoExercise: Double = 32
    
    // Computed properties for display
    private var displaySteps: Int {
        useDemoData ? demoSteps : healthManager.stepCount
    }
    
    private var displaySleep: Double {
        useDemoData ? demoSleep : healthManager.sleepHours
    }
    
    private var displayHeartRate: Double {
        useDemoData ? demoHeartRate : healthManager.heartRate
    }
    
    private var displayRestingHR: Double {
        useDemoData ? demoRestingHR : healthManager.restingHeartRate
    }
    
    private var displayHRV: Double {
        useDemoData ? demoHRV : healthManager.hrv
    }
    
    private var displayCalories: Double {
        useDemoData ? demoCalories : healthManager.activeCalories
    }
    
    private var displayExercise: Double {
        useDemoData ? demoExercise : healthManager.exerciseMinutes
    }
    
    // AI Predictions based on data
    private var energyLevel: Int { calculateEnergy() }
    private var stressLevel: Int { calculateStress() }
    private var healthScore: Int { calculateHealthScore() }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - simplified for performance
                Color(red: 0.07, green: 0.12, blue: 0.17)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerView
                        aiInsightsCard
                        metricsGrid
                        quickActionsRow
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showPredictionInfo) {
            PredictionInfoSheet()
        }
        .onAppear {
            if !useDemoData && lastSyncTime == nil {
                syncHealthData()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                if let syncTime = lastSyncTime {
                    Text("Synced \(syncTime.timeAgoDisplay())")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Sync Button
            Button(action: syncHealthData) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(syncRotation))
                }
            }
            .disabled(isSyncing)
            
            // Demo Toggle
            Button(action: { useDemoData.toggle() }) {
                ZStack {
                    Circle()
                        .fill(useDemoData ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: useDemoData ? "play.fill" : "play")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(useDemoData ? .green : .white)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userProfile.name.isEmpty ? "" : ", \(userProfile.name.components(separatedBy: " ").first ?? "")"
        
        switch hour {
        case 5..<12: return "Good Morning\(name)"
        case 12..<17: return "Good Afternoon\(name)"
        case 17..<22: return "Good Evening\(name)"
        default: return "Good Night\(name)"
        }
    }
    
    // MARK: - AI Insights Card
    
    private var aiInsightsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18))
                    .foregroundColor(.cyan)
                
                Text("AI Health Insights")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showPredictionInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            if hasData {
                VStack(spacing: 12) {
                    PredictionBar(label: "Energy", value: energyLevel, color: energyColor, icon: "bolt.fill")
                    PredictionBar(label: "Stress", value: stressLevel, color: stressColor, icon: "waveform.path.ecg")
                    PredictionBar(label: "Health Score", value: healthScore, color: healthScoreColor, icon: "heart.fill")
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No health data yet")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Sync with Apple Watch or enable demo mode")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.vertical, 16)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var hasData: Bool {
        useDemoData || displaySteps > 0 || displaySleep > 0 || displayHeartRate > 0
    }
    
    // MARK: - Metrics Grid
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            MetricCard(icon: "figure.walk", title: "Steps", value: "\(displaySteps.formatted())", progress: Double(displaySteps) / 10000.0, color: .green)
            MetricCard(icon: "bed.double.fill", title: "Sleep", value: String(format: "%.1fh", displaySleep), progress: displaySleep / 8.0, color: .purple)
            MetricCard(icon: "heart.fill", title: "Heart Rate", value: displayHeartRate > 0 ? "\(Int(displayHeartRate)) bpm" : "--", progress: displayHeartRate > 0 ? min(displayHeartRate / 100.0, 1.0) : 0, color: .red)
            MetricCard(icon: "waveform.path.ecg", title: "HRV", value: displayHRV > 0 ? "\(Int(displayHRV)) ms" : "--", progress: displayHRV > 0 ? min(displayHRV / 80.0, 1.0) : 0, color: .cyan)
            MetricCard(icon: "flame.fill", title: "Calories", value: displayCalories > 0 ? "\(Int(displayCalories))" : "--", progress: displayCalories > 0 ? min(displayCalories / 500.0, 1.0) : 0, color: .orange)
            MetricCard(icon: "figure.run", title: "Exercise", value: displayExercise > 0 ? "\(Int(displayExercise)) min" : "--", progress: displayExercise > 0 ? min(displayExercise / 30.0, 1.0) : 0, color: .yellow)
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: ChatView()
                .environmentObject(healthManager)
                .environmentObject(userProfile)) {
                QuickActionButton(icon: "bubble.left.and.bubble.right.fill", label: "AI Coach", color: .cyan)
            }
            
            NavigationLink(destination: MindfulnessView()) {
                QuickActionButton(icon: "leaf.fill", label: "Mindful", color: .green)
            }
            
            NavigationLink(destination: NutritionView()) {
                QuickActionButton(icon: "fork.knife", label: "Nutrition", color: .orange)
            }
        }
    }
    
    // MARK: - Actions
    
    private func syncHealthData() {
        isSyncing = true
        
        withAnimation(.linear(duration: 1).repeatCount(3)) {
            syncRotation += 360
        }
        
        healthManager.fetchTodayData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSyncing = false
            lastSyncTime = Date()
        }
    }
    
    // MARK: - AI Calculations
    
    private func calculateEnergy() -> Int {
        guard hasData else { return 0 }
        
        var score: Double = 50
        
        // Sleep factor (most important)
        if displaySleep >= 7 && displaySleep <= 9 {
            score += 25
        } else if displaySleep >= 6 {
            score += 10
        } else if displaySleep < 5 {
            score -= 20
        }
        
        // HRV factor
        if displayHRV > 50 {
            score += 15
        } else if displayHRV > 35 {
            score += 5
        } else if displayHRV > 0 && displayHRV < 30 {
            score -= 10
        }
        
        // Activity factor
        if displaySteps > 8000 {
            score += 10
        } else if displaySteps > 5000 {
            score += 5
        }
        
        return Int(min(max(score, 0), 100))
    }
    
    private func calculateStress() -> Int {
        guard hasData else { return 0 }
        
        var stressScore: Double = 20 // Base stress level
        
        // Low HRV = high stress
        if displayHRV > 0 && displayHRV < 30 {
            stressScore += 40
        } else if displayHRV > 0 && displayHRV < 45 {
            stressScore += 20
        }
        
        // Poor sleep = stress
        if displaySleep > 0 && displaySleep < 5 {
            stressScore += 30
        } else if displaySleep > 0 && displaySleep < 6 {
            stressScore += 15
        }
        
        // Elevated HR = stress
        if displayRestingHR > 80 {
            stressScore += 15
        }
        
        return Int(min(max(stressScore, 0), 100))
    }
    
    private func calculateHealthScore() -> Int {
        guard hasData else { return 0 }
        
        var score: Double = 0
        var factors = 0
        
        // Energy contribution (30%)
        score += Double(energyLevel) * 0.3
        factors += 1
        
        // Stress contribution - inverted (25%)
        score += Double(100 - stressLevel) * 0.25
        factors += 1
        
        // Sleep contribution (30%)
        if displaySleep > 0 {
            let sleepScore = min(displaySleep / 8.0, 1.0) * 100
            score += sleepScore * 0.3
            factors += 1
        }
        
        // Activity contribution (15%)
        if displaySteps > 0 {
            let activityScore = min(Double(displaySteps) / 10000.0, 1.0) * 100
            score += activityScore * 0.15
            factors += 1
        }
        
        return factors > 0 ? Int(score) : 0
    }
    
    // MARK: - Colors
    
    private var energyColor: Color {
        switch energyLevel {
        case 0..<40: return .red
        case 40..<70: return .yellow
        default: return .green
        }
    }
    
    private var stressColor: Color {
        switch stressLevel {
        case 0..<40: return .green
        case 40..<70: return .yellow
        default: return .red
        }
    }
    
    private var healthScoreColor: Color {
        switch healthScore {
        case 0..<50: return .red
        case 50..<75: return .yellow
        default: return .green
        }
    }
}

// MARK: - Supporting Views

struct PredictionBar: View {
    let label: String
    let value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100.0)
                }
            }
            .frame(height: 8)
            
            Text("\(value)%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * min(max(progress, 0), 1.0))
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct PredictionInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.11, blue: 0.16).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How AI Predictions Work")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("All predictions run 100% on-device using Llama 3.2 1B")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        InfoSection(icon: "bolt.fill", title: "Energy Level", color: .yellow,
                                    description: "Based on sleep duration, HRV, and daily activity. 7-9 hours sleep and higher HRV = better recovery.")
                        
                        InfoSection(icon: "waveform.path.ecg", title: "Stress Level", color: .red,
                                    description: "Calculated from HRV, resting heart rate, and sleep. Lower HRV and elevated HR suggest higher stress.")
                        
                        InfoSection(icon: "heart.fill", title: "Health Score", color: .green,
                                    description: "Weighted combination: Energy 30%, Sleep 30%, Stress 25% (inverted), Activity 15%.")
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data Sources")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            ForEach(["Sleep duration", "Heart rate", "Resting HR", "HRV", "Steps", "Calories", "Exercise minutes"], id: \.self) { source in
                                HStack(spacing: 8) {
                                    Circle().fill(Color.cyan).frame(width: 6, height: 6)
                                    Text(source)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                        
                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct InfoSection: View {
    let icon: String
    let title: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let seconds = Int(-self.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        else if seconds < 3600 { return "\(seconds / 60)m ago" }
        else if seconds < 86400 { return "\(seconds / 3600)h ago" }
        else { return "\(seconds / 86400)d ago" }
    }
}
