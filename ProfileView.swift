import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var healthManager: HealthDataManager
    @State private var showEditProfile = false
    @State private var showDevices = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.12, blue: 0.17)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader
                        bodyMetricsCard
                        aiEngineCard
                        healthStatsCard
                        goalsCard
                        devicesCard
                        settingsCard
                        appInfoCard
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet()
                .environmentObject(userProfile)
        }
        .sheet(isPresented: $showDevices) {
            NavigationView {
                DeviceIntegrationView()
                    .environmentObject(healthManager)
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text(userProfile.name.prefix(1).uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(userProfile.name.isEmpty ? "Your Name" : userProfile.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("MindFull Member")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Button(action: { showEditProfile = true }) {
                Text("Edit Profile")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(Color.cyan, lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Body Metrics Card (BMI)
    
    private var bodyMetricsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.stand")
                    .font(.system(size: 18))
                    .foregroundColor(.purple)
                
                Text("Body Metrics")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showEditProfile = true }) {
                    Text("Edit")
                        .font(.system(size: 14))
                        .foregroundColor(.cyan)
                }
            }
            
            HStack(spacing: 20) {
                MetricBox(label: "Height", value: "\(Int(userProfile.heightCm)) cm", icon: "ruler")
                MetricBox(label: "Weight", value: "\(Int(userProfile.weightKg)) kg", icon: "scalemass")
                MetricBox(label: "BMI", value: String(format: "%.1f", userProfile.bmi), icon: "heart.text.square", subtitle: userProfile.bmiCategory)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - AI Engine Card
    
    private var aiEngineCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 18))
                    .foregroundColor(.cyan)
                
                Text("AI Engine")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Active")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green.opacity(0.2)))
            }
            
            VStack(spacing: 12) {
                ProfileInfoRow(icon: "brain", label: "Model", value: "Llama 3.2 1B Instruct")
                ProfileInfoRow(icon: "memorychip", label: "Processing", value: "100% On-Device")
                ProfileInfoRow(icon: "lock.shield", label: "Privacy", value: "Data never leaves device")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Health Stats Card
    
    private var healthStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
                
                Text("Today's Health")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatBox(label: "Steps", value: "\(healthManager.stepCount.formatted())", icon: "figure.walk")
                StatBox(label: "Sleep", value: String(format: "%.1fh", healthManager.sleepHours), icon: "bed.double.fill")
                StatBox(label: "Resting HR", value: healthManager.restingHeartRate > 0 ? "\(Int(healthManager.restingHeartRate))" : "--", icon: "heart.fill")
                StatBox(label: "HRV", value: healthManager.hrv > 0 ? "\(Int(healthManager.hrv))ms" : "--", icon: "waveform.path.ecg")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Goals Card
    
    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
                
                Text("Daily Goals")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showEditProfile = true }) {
                    Text("Edit")
                        .font(.system(size: 14))
                        .foregroundColor(.cyan)
                }
            }
            
            VStack(spacing: 12) {
                GoalRow(icon: "figure.walk", label: "Steps", value: "\(userProfile.dailyStepGoal.formatted())", color: .green)
                GoalRow(icon: "bed.double.fill", label: "Sleep", value: "\(String(format: "%.0f", userProfile.sleepGoalHours)) hours", color: .purple)
                GoalRow(icon: "flame.fill", label: "Calories", value: "\(userProfile.dailyCalorieGoal)", color: .orange)
                GoalRow(icon: "drop.fill", label: "Water", value: "2,000 ml", color: .blue)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Devices Card
    
    private var devicesCard: some View {
        Button(action: { showDevices = true }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "applewatch.and.arrow.forward")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connected Devices")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Apple Watch, Libre CGM, Oura Ring & more")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    // MARK: - Settings Card
    
    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                
                Text("Settings")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 0) {
                SettingsRow(icon: "bell.fill", label: "Notifications", hasToggle: true)
                Divider().background(Color.white.opacity(0.1))
                SettingsRow(icon: "heart.text.square", label: "Health Permissions", hasArrow: true)
                Divider().background(Color.white.opacity(0.1))
                SettingsRow(icon: "hand.raised.fill", label: "Privacy", hasArrow: true)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var appInfoCard: some View {
        VStack(spacing: 12) {
            Text("MindFull AI")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Version 1.0.0")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Built for Arm AI Developer Challenge 2025")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Metric Box

struct MetricBox: View {
    let label: String
    let value: String
    let icon: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.purple)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(bmiColor(subtitle))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func bmiColor(_ category: String) -> Color {
        switch category {
        case "Normal": return .green
        case "Underweight": return .yellow
        case "Overweight": return .orange
        default: return .red
        }
    }
}

// MARK: - Supporting Views

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan.opacity(0.7))
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.cyan)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct GoalRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
}

struct SettingsRow: View {
    let icon: String
    let label: String
    var hasToggle: Bool = false
    var hasArrow: Bool = false
    
    @State private var isOn = true
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white)
            
            Spacer()
            
            if hasToggle {
                Toggle("", isOn: $isOn)
                    .tint(.cyan)
            }
            
            if hasArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Edit Profile Sheet (FULL)

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfile: UserProfile
    
    @State private var name: String = ""
    @State private var age: Double = 25
    @State private var gender: String = "Other"
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var stepGoal: Double = 10000
    @State private var calorieGoal: Double = 2000
    @State private var sleepGoal: Double = 8
    
    var bmi: Double {
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }
    
    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.11, blue: 0.16)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("Your name", text: $name)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                )
                                .foregroundColor(.white)
                        }
                        
                        // Age & Gender
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Age: \(Int(age))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Slider(value: $age, in: 13...100, step: 1)
                                    .tint(.cyan)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Picker("Gender", selection: $gender) {
                                    Text("Male").tag("Male")
                                    Text("Female").tag("Female")
                                    Text("Other").tag("Other")
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        // Height
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Height")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("\(Int(heightCm)) cm (\(String(format: "%.1f", heightCm / 30.48)) ft)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }
                            
                            Slider(value: $heightCm, in: 120...220, step: 1)
                                .tint(.cyan)
                        }
                        
                        // Weight
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Weight")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("\(Int(weightKg)) kg (\(String(format: "%.0f", weightKg * 2.205)) lbs)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }
                            
                            Slider(value: $weightKg, in: 30...200, step: 1)
                                .tint(.cyan)
                        }
                        
                        // BMI Preview
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BMI")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                Text(String(format: "%.1f", bmi))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text(bmiCategory)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(bmiColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(bmiColor.opacity(0.2))
                                )
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        // Goals Section
                        Text("Daily Goals")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Step Goal
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Step Goal")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("\(Int(stepGoal).formatted())")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            Slider(value: $stepGoal, in: 3000...20000, step: 500)
                                .tint(.green)
                        }
                        
                        // Calorie Goal
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Calorie Goal")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("\(Int(calorieGoal))")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            Slider(value: $calorieGoal, in: 1200...4000, step: 100)
                                .tint(.orange)
                        }
                        
                        // Sleep Goal
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Sleep Goal")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("\(Int(sleepGoal)) hours")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.purple)
                            }
                            Slider(value: $sleepGoal, in: 5...12, step: 0.5)
                                .tint(.purple)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadProfile()
        }
    }
    
    private var bmiColor: Color {
        switch bmiCategory {
        case "Normal": return .green
        case "Underweight": return .yellow
        case "Overweight": return .orange
        default: return .red
        }
    }
    
    private func loadProfile() {
        name = userProfile.name
        age = Double(userProfile.age)
        gender = userProfile.gender
        heightCm = userProfile.heightCm
        weightKg = userProfile.weightKg
        stepGoal = Double(userProfile.dailyStepGoal)
        calorieGoal = Double(userProfile.dailyCalorieGoal)
        sleepGoal = userProfile.sleepGoalHours
    }
    
    private func saveProfile() {
        userProfile.name = name
        userProfile.age = Int(age)
        userProfile.gender = gender
        userProfile.heightCm = heightCm
        userProfile.weightKg = weightKg
        userProfile.dailyStepGoal = Int(stepGoal)
        userProfile.dailyCalorieGoal = Int(calorieGoal)
        userProfile.sleepGoalHours = sleepGoal
        userProfile.isProfileComplete = true
        userProfile.saveProfile()
    }
}

