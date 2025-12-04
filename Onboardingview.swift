import SwiftUI
import Combine

struct OnboardingView: View {
    @EnvironmentObject var userProfile: UserProfile
    @Binding var showOnboarding: Bool
    
    @State private var currentPage = 0
    @State private var name = ""
    @State private var age = 25
    @State private var gender = "Other"
    @State private var heightCm = 170.0
    @State private var weightKg = 70.0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.3),
                    Color(red: 0.15, green: 0.25, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(index <= currentPage ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color.white.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 60)
                
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    namePage.tag(1)
                    bodyMetricsPage.tag(2)
                    goalPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }
    
    var welcomePage: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.2))
                    .frame(width: 180, height: 180)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
            }
            
            VStack(spacing: 16) {
                Text("Welcome to MindFull AI")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Your personal AI health coach,\npowered entirely on-device")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Features
            VStack(spacing: 16) {
                FeatureRow(icon: "cpu", text: "100% On-Device AI")
                FeatureRow(icon: "lock.shield.fill", text: "Private & Secure")
                FeatureRow(icon: "heart.fill", text: "HealthKit Integration")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            nextButton
        }
        .padding(20)
    }
    
    var namePage: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("What's your name?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("So I can personalize your experience")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            TextField("Enter your name", text: $name)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.1))
                )
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Age picker
            VStack(spacing: 12) {
                Text("Your age")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                Picker("Age", selection: $age) {
                    ForEach(13..<100) { age in
                        Text("\(age) years").tag(age)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            }
            
            // Gender picker
            VStack(spacing: 12) {
                Text("Gender")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 12) {
                    ForEach(["Male", "Female", "Other"], id: \.self) { g in
                        Button(action: { gender = g }) {
                            Text(g)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(gender == g ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(gender == g ? Color(red: 0.4, green: 0.8, blue: 0.6) : .white.opacity(0.1))
                                )
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            nextButton
        }
        .padding(20)
    }
    
    var bodyMetricsPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Body Metrics")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("For accurate health calculations")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Height
            VStack(spacing: 16) {
                Text("Height")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Text("\(Int(heightCm)) cm")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    
                    Text("(\(String(format: "%.1f", heightCm / 30.48)) ft)")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Slider(value: $heightCm, in: 120...220, step: 1)
                    .tint(Color(red: 0.4, green: 0.8, blue: 0.6))
                    .padding(.horizontal, 40)
            }
            
            // Weight
            VStack(spacing: 16) {
                Text("Weight")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Text("\(Int(weightKg)) kg")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    
                    Text("(\(String(format: "%.0f", weightKg * 2.205)) lbs)")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Slider(value: $weightKg, in: 30...200, step: 1)
                    .tint(Color(red: 0.4, green: 0.8, blue: 0.6))
                    .padding(.horizontal, 40)
            }
            
            // BMI Preview
            let bmi = weightKg / pow(heightCm / 100, 2)
            VStack(spacing: 8) {
                Text("BMI: \(String(format: "%.1f", bmi))")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(bmiCategory(bmi))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
            )
            
            Spacer()
            
            nextButton
        }
        .padding(20)
    }
    
    var goalPage: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
            }
            
            VStack(spacing: 16) {
                Text("You're all set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your AI health coach is ready to help you\nachieve your wellness goals")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Summary
            VStack(spacing: 12) {
                SummaryRow(label: "Name", value: name.isEmpty ? "User" : name)
                SummaryRow(label: "Age", value: "\(age) years")
                SummaryRow(label: "Height", value: "\(Int(heightCm)) cm")
                SummaryRow(label: "Weight", value: "\(Int(weightKg)) kg")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.1))
            )
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: completeOnboarding) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding(20)
    }
    
    var nextButton: some View {
        Button(action: {
            withAnimation {
                currentPage += 1
            }
        }) {
            Text("Continue")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                )
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
    }
    
    func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
    
    func completeOnboarding() {
        // Save to user profile
        userProfile.name = name.isEmpty ? "User" : name
        userProfile.age = age
        userProfile.gender = gender
        userProfile.heightCm = heightCm
        userProfile.weightKg = weightKg
        userProfile.saveProfile()
        
        // Dismiss onboarding
        withAnimation {
            showOnboarding = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environmentObject(UserProfile())
}
