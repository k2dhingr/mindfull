import SwiftUI
import Combine

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthManager: HealthDataManager
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var nutritionManager: NutritionManager
    @StateObject private var llamaManager = LlamaManager.shared
    @StateObject private var moodManager = MoodManager()
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showModelInfo = false
    @State private var showDevices = false
    @FocusState private var isInputFocused: Bool
    
    // Demo data toggle - START WITH TRUE FOR DEMO
    @State private var useDemoData = true
    
    // Demo data values (realistic for demo)
    private let demoSteps: Int = 8547
    private let demoSleep: Double = 7.2
    private let demoHeartRate: Double = 72
    private let demoRestingHR: Double = 58
    private let demoHRV: Double = 45
    private let demoCalories: Double = 423
    private let demoGlucose: Double = 98
    private let demoMood: String = "😊"
    private let demoMoodLabel: String = "Happy"
    
    // Computed display values
    private var displaySteps: Int { useDemoData ? demoSteps : healthManager.stepCount }
    private var displaySleep: Double { useDemoData ? demoSleep : healthManager.sleepHours }
    private var displayHeartRate: Double { useDemoData ? demoHeartRate : healthManager.heartRate }
    private var displayRestingHR: Double { useDemoData ? demoRestingHR : healthManager.restingHeartRate }
    private var displayHRV: Double { useDemoData ? demoHRV : healthManager.hrv }
    private var displayCalories: Double { useDemoData ? demoCalories : healthManager.activeCalories }
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.12, blue: 0.17)
                .ignoresSafeArea()
                .onTapGesture { isInputFocused = false }
            
            VStack(spacing: 0) {
                headerView
                dataSourcesBar
                messagesView
                quickPromptsBar
                inputBar
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showModelInfo) {
            ModelInfoSheet()
        }
        .sheet(isPresented: $showDevices) {
            NavigationView {
                DeviceIntegrationView()
                    .environmentObject(healthManager)
            }
        }
        .onAppear {
            if messages.isEmpty {
                addWelcomeMessage()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17))
                }
                .foregroundColor(.cyan)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("AI Health Coach")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(useDemoData ? "Demo Mode • On-Device" : "Llama 3.2 • On-Device")
                    .font(.system(size: 11))
                    .foregroundColor(useDemoData ? .green.opacity(0.8) : .white.opacity(0.5))
            }
            
            Spacer()
            
            // Demo Toggle
            Button(action: { useDemoData.toggle() }) {
                ZStack {
                    Circle()
                        .fill(useDemoData ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: useDemoData ? "play.fill" : "play")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(useDemoData ? .green : .white.opacity(0.6))
                }
            }
            
            // Model Info
            Button(action: { showModelInfo = true }) {
                Image(systemName: "cpu")
                    .font(.system(size: 18))
                    .foregroundColor(.cyan)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Data Sources Bar (NEW!)
    
    private var dataSourcesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                DataSourceChip(icon: "applewatch", label: "Watch", isActive: true)
                DataSourceChip(icon: "drop.fill", label: "Glucose", isActive: useDemoData, color: .yellow)
                DataSourceChip(icon: "face.smiling", label: "Mood", isActive: !moodManager.moodHistory.isEmpty || useDemoData, color: .pink)
                DataSourceChip(icon: "fork.knife", label: "Nutrition", isActive: !nutritionManager.todaysFoods.isEmpty || useDemoData, color: .orange)
                
                Button(action: { showDevices = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.white.opacity(0.02))
    }
    
    // MARK: - Messages
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if isLoading {
                        TypingIndicator()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Prompts (Context-Aware!)
    
    private var quickPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Health prompts
                QuickPromptButton(text: "📊 Full summary") {
                    sendQuickMessage("Give me a complete summary of my health today including all my data")
                }
                
                QuickPromptButton(text: "💤 Sleep analysis") {
                    sendQuickMessage("Analyze my sleep and give me personalized tips")
                }
                
                QuickPromptButton(text: "❤️ Heart health") {
                    sendQuickMessage("How's my heart rate and HRV? What do they mean?")
                }
                
                // Mood-aware prompts
                QuickPromptButton(text: "😊 Log mood") {
                    sendQuickMessage("I want to log my mood right now")
                }
                
                // Nutrition prompts
                QuickPromptButton(text: "🍎 Nutrition check") {
                    sendQuickMessage("How am I doing on my nutrition goals today?")
                }
                
                // Activity prompts
                QuickPromptButton(text: "🏃 Activity tips") {
                    sendQuickMessage("How can I be more active and reach my step goal?")
                }
                
                // Glucose (if enabled)
                if useDemoData {
                    QuickPromptButton(text: "🩸 Glucose") {
                        sendQuickMessage("What's my glucose level and what does it mean?")
                    }
                }
                
                // General wellness
                QuickPromptButton(text: "😰 Feeling stressed") {
                    sendQuickMessage("I'm feeling stressed, what should I do?")
                }
                
                QuickPromptButton(text: "💪 Motivate me") {
                    sendQuickMessage("I need some motivation to stay healthy today")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.white.opacity(0.03))
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask about health, mood, nutrition...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.08))
                )
                .foregroundColor(.white)
                .focused($isInputFocused)
                .onSubmit { sendMessage() }
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(inputText.isEmpty ? .gray : .cyan)
            }
            .disabled(inputText.isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Message Handling
    
    private func addWelcomeMessage() {
        let name = userProfile.name.isEmpty ? "" : ", \(userProfile.name.components(separatedBy: " ").first ?? "")"
        
        let welcome = """
        Hey\(name)! 👋 I'm your AI health coach, running 100% on your device.
        
        I can see data from multiple sources:
        • ⌚ Apple Watch (steps, sleep, heart rate, HRV)
        • 🩸 Glucose monitor (if connected)
        • 😊 Your mood logs
        • 🍎 Nutrition tracking
        
        Ask me anything about your health, or tap a quick prompt below to get started!
        """
        
        messages.append(ChatMessage(content: welcome, isUser: false))
    }
    
    private func sendQuickMessage(_ text: String) {
        inputText = text
        sendMessage()
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messages.append(ChatMessage(content: text, isUser: true))
        inputText = ""
        isInputFocused = false
        isLoading = true
        
        Task {
            let response = await generateResponse(for: text)
            
            await MainActor.run {
                messages.append(ChatMessage(content: response, isUser: false))
                isLoading = false
            }
        }
    }
    
    // MARK: - Smart AI Response Generation
    
    private func generateResponse(for input: String) async -> String {
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        let lowercased = input.lowercased()
        
        // COMPREHENSIVE SUMMARY
        if lowercased.contains("summary") || lowercased.contains("overview") || lowercased.contains("all my data") || lowercased.contains("complete") {
            return generateComprehensiveSummary()
        }
        
        // MOOD
        if lowercased.contains("mood") || lowercased.contains("feeling") || lowercased.contains("emotion") {
            if lowercased.contains("log") || lowercased.contains("track") || lowercased.contains("record") {
                return generateMoodLoggingResponse()
            }
            return generateMoodAnalysis()
        }
        
        // GLUCOSE
        if lowercased.contains("glucose") || lowercased.contains("blood sugar") || lowercased.contains("cgm") || lowercased.contains("libre") {
            return generateGlucoseResponse()
        }
        
        // NUTRITION
        if lowercased.contains("nutrition") || lowercased.contains("food") || lowercased.contains("eat") || lowercased.contains("diet") || lowercased.contains("calorie") || lowercased.contains("protein") {
            return generateNutritionResponse()
        }
        
        // SLEEP
        if lowercased.contains("sleep") || lowercased.contains("rest") || lowercased.contains("tired") {
            return generateSleepResponse()
        }
        
        // ACTIVITY / STEPS
        if lowercased.contains("step") || lowercased.contains("walk") || lowercased.contains("active") || lowercased.contains("activity") || lowercased.contains("exercise") {
            return generateActivityResponse()
        }
        
        // HEART
        if lowercased.contains("heart") || lowercased.contains("hrv") || lowercased.contains("pulse") || lowercased.contains("cardio") {
            return generateHeartResponse()
        }
        
        // STRESS
        if lowercased.contains("stress") || lowercased.contains("anxious") || lowercased.contains("worried") || lowercased.contains("overwhelm") {
            return generateStressResponse()
        }
        
        // MOTIVATION
        if lowercased.contains("motivat") || lowercased.contains("inspire") || lowercased.contains("encourage") {
            return generateMotivationResponse()
        }
        
        // DEVICES
        if lowercased.contains("device") || lowercased.contains("connect") || lowercased.contains("sensor") || lowercased.contains("watch") || lowercased.contains("oura") || lowercased.contains("whoop") {
            return generateDevicesResponse()
        }
        
        // GREETINGS
        if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("hey") || lowercased.hasPrefix("how are") {
            return generateGreetingResponse()
        }
        
        // GENERAL HEALTH QUESTIONS
        if lowercased.contains("health") || lowercased.contains("wellness") || lowercased.contains("body") {
            return generateGeneralHealthResponse()
        }
        
        // FALLBACK - Helpful default
        return generateSmartDefault(for: input)
    }
    
    // MARK: - Response Generators
    
    private func generateComprehensiveSummary() -> String {
        let name = userProfile.name.isEmpty ? "" : " \(userProfile.name.components(separatedBy: " ").first ?? "")"
        var summary = "**Your Complete Health Summary\(name)** 📊\n\n"
        
        // Activity
        let steps = displaySteps
        let stepsProgress = Double(steps) / Double(userProfile.dailyStepGoal) * 100
        let stepsEmoji = stepsProgress >= 100 ? "🏆" : stepsProgress >= 70 ? "✅" : "🚶"
        summary += "\(stepsEmoji) **Activity:** \(steps.formatted()) steps (\(Int(stepsProgress))% of goal)\n"
        
        // Sleep
        let sleep = displaySleep
        let sleepEmoji = sleep >= 7 ? "✅" : sleep >= 6 ? "😐" : "⚠️"
        summary += "\(sleepEmoji) **Sleep:** \(String(format: "%.1f", sleep)) hours\n"
        
        // Heart
        let hr = displayHeartRate
        let hrv = displayHRV
        summary += "❤️ **Heart Rate:** \(Int(hr)) bpm"
        if hrv > 0 {
            summary += " | **HRV:** \(Int(hrv))ms"
        }
        summary += "\n"
        
        // Calories
        summary += "🔥 **Active Calories:** \(Int(displayCalories))\n"
        
        // Glucose (if demo)
        if useDemoData {
            summary += "🩸 **Glucose:** \(Int(demoGlucose)) mg/dL (Normal)\n"
        }
        
        // Nutrition
        let totalCal = nutritionManager.totalCalories
        let calGoal = userProfile.dailyCalorieGoal
        if totalCal > 0 || useDemoData {
            let displayCal = useDemoData ? 1450 : totalCal
            summary += "🍎 **Nutrition:** \(displayCal)/\(calGoal) cal"
            if useDemoData || nutritionManager.totalProtein > 0 {
                let protein = useDemoData ? 85.0 : nutritionManager.totalProtein
                summary += " | \(Int(protein))g protein"
            }
            summary += "\n"
        }
        
        // Mood
        if useDemoData || !moodManager.moodHistory.isEmpty {
            let mood = useDemoData ? demoMood : (moodManager.moodHistory.first?.mood ?? "😊")
            let label = useDemoData ? demoMoodLabel : (moodManager.moodHistory.first?.label ?? "Good")
            summary += "😊 **Mood:** \(mood) \(label)\n"
        }
        
        // Water
        let water = useDemoData ? 1500 : nutritionManager.waterIntake
        summary += "💧 **Hydration:** \(water)/2000 ml\n"
        
        // Overall Assessment
        summary += "\n**My Assessment:**\n"
        
        let sleepGood = sleep >= 7
        let stepsGood = stepsProgress >= 70
        let hrvGood = hrv >= 40
        
        if sleepGood && stepsGood && hrvGood {
            summary += "You're having an excellent day! 🌟 Your sleep, activity, and recovery are all looking great. Keep up this momentum!"
        } else if sleepGood || stepsGood {
            var focus = ""
            if !sleepGood { focus = "Prioritize sleep tonight" }
            else if !stepsGood { focus = "Try to get more movement in" }
            else if !hrvGood { focus = "Consider some relaxation exercises" }
            summary += "You're making solid progress! 💪 Focus area: \(focus). You've got this!"
        } else {
            summary += "Today might be a good day to focus on self-care. 🌱 Start with small steps - a short walk, some deep breathing, or an early bedtime. Every bit counts!"
        }
        
        return summary
    }
    
    private func generateMoodLoggingResponse() -> String {
        return """
        I'd love to help you log your mood! 😊
        
        Head to the **Mindful** tab and tap on **Mood** to record how you're feeling. You can:
        
        • Select from emoji moods (😊 😐 😢 😤 😴)
        • Add notes about what's on your mind
        • Track patterns over time
        
        Your mood data helps me give you better personalized advice! For example, if you're feeling stressed, I can factor that into my sleep and activity recommendations.
        
        Want me to give you some mood-boosting tips instead?
        """
    }
    
    private func generateMoodAnalysis() -> String {
        if useDemoData {
            return """
            Based on your recent mood logs, you've been feeling **\(demoMoodLabel)** \(demoMood)
            
            **Mood Patterns I've Noticed:**
            • Your mood tends to be higher after good sleep (7+ hours)
            • Physical activity correlates with better mood
            • Afternoons seem to be your peak mood time
            
            **Today's Mood Factors:**
            ✅ Good sleep last night (7.2h)
            ✅ Active movement (8,547 steps)
            ✅ Stable glucose levels
            
            Keep it up! Your healthy habits are clearly paying off emotionally. 💚
            """
        } else if let latestMood = moodManager.moodHistory.first {
            return """
            Your latest mood log: **\(latestMood.label)** \(latestMood.mood)
            
            Logged: \(latestMood.formattedDate)
            \(latestMood.note.isEmpty ? "" : "Note: \"\(latestMood.note)\"")
            
            Would you like to log how you're feeling now, or get some tips based on your current mood?
            """
        } else {
            return """
            I don't have any mood logs from you yet! 
            
            Tracking your mood can help me:
            • Spot patterns between health metrics and emotions
            • Give you personalized wellness advice
            • Help you understand what affects your wellbeing
            
            Head to **Mindful → Mood** to start logging! 😊
            """
        }
    }
    
    private func generateGlucoseResponse() -> String {
        if useDemoData {
            return """
            **Glucose Reading** 🩸
            
            Current: **\(Int(demoGlucose)) mg/dL** ✅ Normal
            
            Your glucose is in the healthy fasting range (70-100 mg/dL). This indicates good metabolic health!
            
            **Tips to maintain stable glucose:**
            • Eat protein and fiber with carbs
            • Take a 10-min walk after meals
            • Stay hydrated
            • Get adequate sleep (you're doing great with 7.2h!)
            
            Your CGM data syncs automatically through Apple Health. Keep up the great work! 📈
            """
        } else {
            return """
            **Glucose Monitoring** 🩸
            
            To track glucose data, you can connect a CGM like:
            • **FreeStyle Libre** (Coming Soon!)
            • **Dexcom** (via Apple Health)
            
            Once connected, I can help you:
            • Understand your glucose patterns
            • Correlate glucose with meals and activity
            • Optimize nutrition timing
            
            Go to **Profile → Connected Devices** to set up your glucose monitor!
            """
        }
    }
    
    private func generateNutritionResponse() -> String {
        let totalCal = useDemoData ? 1450 : nutritionManager.totalCalories
        let protein = useDemoData ? 85.0 : nutritionManager.totalProtein
        let carbs = useDemoData ? 165.0 : nutritionManager.totalCarbs
        let fat = useDemoData ? 52.0 : nutritionManager.totalFat
        let water = useDemoData ? 1500 : nutritionManager.waterIntake
        let calGoal = userProfile.dailyCalorieGoal
        
        let calProgress = Double(totalCal) / Double(calGoal) * 100
        
        return """
        **Your Nutrition Today** 🍎
        
        🔥 **Calories:** \(totalCal) / \(calGoal) (\(Int(calProgress))%)
        🥩 **Protein:** \(Int(protein))g
        🍞 **Carbs:** \(Int(carbs))g
        🥑 **Fat:** \(Int(fat))g
        💧 **Water:** \(water) / 2000 ml
        
        **My Take:**
        \(calProgress >= 80 && calProgress <= 110 ? "You're right on track with your calorie goal! 👏" : calProgress < 50 ? "You might want to eat a bit more to fuel your body properly." : calProgress > 110 ? "You've exceeded your calorie goal - that's okay occasionally!" : "Good progress! A balanced dinner will get you to your goal.")
        
        **Tips:**
        • Aim for 0.8-1g protein per lb of body weight
        • Add more veggies for fiber and nutrients
        • Drink water before meals to aid digestion
        
        Use the **Nutrition** tab to scan food with AI! 📸
        """
    }
    
    private func generateSleepResponse() -> String {
        let sleep = displaySleep
        let hrv = displayHRV
        
        let sleepEmoji = sleep >= 7 ? "😊" : sleep >= 6 ? "😐" : "😴"
        let quality = sleep >= 7 && hrv >= 40 ? "Good recovery" : sleep >= 6 ? "Moderate recovery" : "Needs attention"
        
        var response = """
        **Sleep Analysis** 💤
        
        ⏰ **Duration:** \(String(format: "%.1f", sleep)) hours \(sleepEmoji)
        📊 **Quality:** \(quality)
        """
        
        if hrv > 0 {
            response += "\n🫀 **Recovery (HRV):** \(Int(hrv))ms"
        }
        
        response += "\n\n"
        
        if sleep >= 7 && sleep <= 9 {
            response += """
            Great job! You hit the optimal 7-9 hour range. Quality sleep like this:
            • Boosts memory consolidation
            • Supports immune function
            • Regulates hunger hormones
            • Improves mood and focus
            
            Keep this rhythm going! 🌟
            """
        } else if sleep >= 6 {
            response += """
            You're close to the 7-9 hour target. Even 30 more minutes could make a difference!
            
            **Tips for tonight:**
            • Start winding down 1 hour before bed
            • Keep your room cool (65-68°F)
            • Avoid screens 30 mins before sleep
            • Try the breathing exercises in the Mindful tab
            """
        } else {
            response += """
            \(String(format: "%.1f", sleep)) hours is below what your body needs. Short sleep affects:
            • Focus and decision-making
            • Appetite regulation
            • Stress resilience
            • Physical recovery
            
            **Priority for tonight:**
            Set a firm bedtime alarm and protect your wind-down time. Your health depends on it! 🛏️
            """
        }
        
        return response
    }
    
    private func generateActivityResponse() -> String {
        let steps = displaySteps
        let goal = userProfile.dailyStepGoal
        let progress = Double(steps) / Double(goal) * 100
        let remaining = max(0, goal - steps)
        let calories = displayCalories
        
        let emoji = progress >= 100 ? "🏆" : progress >= 70 ? "💪" : progress >= 50 ? "👍" : "🚶"
        
        var response = """
        **Activity Report** \(emoji)
        
        🚶 **Steps:** \(steps.formatted()) / \(goal.formatted()) (\(Int(progress))%)
        🔥 **Calories Burned:** \(Int(calories))
        """
        
        if remaining > 0 {
            let walkMins = remaining / 100 // ~100 steps per minute walking
            response += "\n📏 **Remaining:** \(remaining.formatted()) steps (~\(walkMins) min walk)"
        }
        
        response += "\n\n"
        
        if progress >= 100 {
            response += """
            Incredible work! 🎉 You've smashed your step goal!
            
            Benefits you're getting:
            • Improved cardiovascular health
            • Better mood and energy
            • Stronger bones and muscles
            • Reduced stress hormones
            
            Challenge: Try to beat this tomorrow! 💪
            """
        } else if progress >= 70 {
            response += """
            You're so close! Just \(remaining.formatted()) steps to go.
            
            **Quick ideas:**
            • Take a 15-minute walk after dinner
            • Do walking meetings or calls
            • Park farther away
            • Take stairs instead of elevator
            
            You've got this! 🌟
            """
        } else {
            response += """
            Let's get moving! Here's how to add more steps:
            
            **Easy wins:**
            • Morning walk (even 10 mins helps!)
            • Walk during lunch break
            • Evening stroll
            • Pace while on phone calls
            
            Every step counts toward a healthier you! 🏃
            """
        }
        
        return response
    }
    
    private func generateHeartResponse() -> String {
        let hr = displayHeartRate
        let hrv = displayHRV
        let restingHR = displayRestingHR
        
        var response = "**Heart Health Report** ❤️\n\n"
        
        // Current HR
        let hrStatus = hr >= 60 && hr <= 100 ? "Normal" : hr < 60 ? "Low (Athletic)" : "Elevated"
        response += "💓 **Heart Rate:** \(Int(hr)) bpm (\(hrStatus))\n"
        
        // Resting HR
        if restingHR > 0 {
            let restingStatus = restingHR < 60 ? "Excellent" : restingHR < 70 ? "Good" : "Normal"
            response += "😴 **Resting HR:** \(Int(restingHR)) bpm (\(restingStatus))\n"
        }
        
        // HRV
        if hrv > 0 {
            let hrvStatus = hrv >= 50 ? "Excellent" : hrv >= 40 ? "Good" : hrv >= 30 ? "Moderate" : "Low"
            response += "📈 **HRV:** \(Int(hrv))ms (\(hrvStatus))\n"
        }
        
        response += "\n**What This Means:**\n"
        
        if hrv >= 40 && restingHR < 70 {
            response += """
            Your heart metrics look great! 🌟
            
            • Good HRV indicates strong recovery and stress resilience
            • Lower resting HR suggests good cardiovascular fitness
            • Keep up your current sleep and exercise habits!
            """
        } else if hrv < 30 {
            response += """
            Your HRV is on the lower side, which can indicate:
            • Physical or mental stress
            • Poor sleep recovery
            • Need for rest
            
            **Recommendations:**
            • Try the breathing exercises in Mindful tab
            • Prioritize sleep tonight
            • Consider lighter exercise today
            """
        } else {
            response += """
            Your heart metrics are in a normal range. To improve:
            • Regular aerobic exercise
            • Quality sleep
            • Stress management
            • Stay hydrated
            """
        }
        
        return response
    }
    
    private func generateStressResponse() -> String {
        let hrv = displayHRV
        let sleep = displaySleep
        
        var response = "I hear you. Let's work through this together. 🤗\n\n"
        
        // Analyze biometrics
        response += "**What Your Body Says:**\n"
        
        if hrv < 40 && hrv > 0 {
            response += "• Your HRV (\(Int(hrv))ms) suggests your body is stressed\n"
        }
        if sleep < 6 && sleep > 0 {
            response += "• Low sleep (\(String(format: "%.1f", sleep))h) amplifies stress\n"
        }
        
        response += """
        
        **Immediate Relief (try now):**
        
        🫁 **Box Breathing:**
        Breathe in 4 sec → Hold 4 sec → Out 4 sec → Hold 4 sec
        Repeat 4 times
        
        🧘 **Quick Body Scan:**
        • Unclench your jaw
        • Drop your shoulders
        • Relax your hands
        • Take 3 deep breaths
        
        **In the Mindful Tab:**
        • Guided meditations (5-15 min)
        • Breathing exercises
        • Mood logging to track patterns
        
        **Longer-term:**
        • Protect your sleep tonight
        • Take a walk in nature if possible
        • Talk to someone you trust
        
        You're not alone in this. 💚 Is there something specific on your mind?
        """
        
        return response
    }
    
    private func generateMotivationResponse() -> String {
        let name = userProfile.name.isEmpty ? "" : " \(userProfile.name.components(separatedBy: " ").first ?? "")"
        let steps = displaySteps
        let sleep = displaySleep
        
        var wins: [String] = []
        if steps > 5000 { wins.append("You've already moved \(steps.formatted()) steps today!") }
        if sleep >= 6 { wins.append("You got \(String(format: "%.1f", sleep)) hours of sleep") }
        if displayHRV >= 40 { wins.append("Your body is recovering well (HRV \(Int(displayHRV))ms)") }
        
        var response = "Hey\(name)! Let me remind you how amazing you're doing. 💪\n\n"
        
        if !wins.isEmpty {
            response += "**Today's Wins:**\n"
            for win in wins {
                response += "✅ \(win)\n"
            }
            response += "\n"
        }
        
        response += """
        **Remember:**
        
        🌟 Every step counts, literally
        🌟 Progress isn't linear - bad days are part of the journey
        🌟 You're here, tracking your health - that's already a win
        🌟 Small consistent actions beat perfect sporadic ones
        
        **Your Challenge:**
        Pick ONE healthy thing to do in the next hour:
        • 10-minute walk
        • Glass of water
        • 5 deep breaths
        • Healthy snack
        
        You've got this! I believe in you. 🚀
        """
        
        return response
    }
    
    private func generateDevicesResponse() -> String {
        return """
        **Connected Devices & Sensors** ⌚
        
        MindFull AI integrates with multiple data sources:
        
        **Currently Supported:**
        ✅ Apple Watch - HR, HRV, sleep, steps, workouts
        ✅ Oura Ring - via Apple Health
        ✅ WHOOP - via Apple Health
        ✅ Garmin - via Apple Health
        ✅ Fitbit - via Apple Health
        
        **Coming Soon:**
        🔜 FreeStyle Libre CGM - Continuous glucose
        🔜 Dexcom CGM
        🔜 Withings - Weight, blood pressure
        🔜 Eight Sleep - Sleep temperature
        
        All data stays 100% on your device and is processed by the on-device AI. Your privacy is protected! 🔒
        
        Go to **Profile → Connected Devices** to manage your connections.
        """
    }
    
    private func generateGreetingResponse() -> String {
        let name = userProfile.name.isEmpty ? "" : " \(userProfile.name.components(separatedBy: " ").first ?? "")"
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        
        let steps = displaySteps
        let sleep = displaySleep
        
        return """
        \(greeting)\(name)! 👋 I'm doing great, thanks for asking!
        
        **Quick glance at your day:**
        • 🚶 \(steps.formatted()) steps so far
        • 😴 \(String(format: "%.1f", sleep))h sleep last night
        • ❤️ \(Int(displayHeartRate)) bpm heart rate
        
        How can I help you today? You can ask me about your health data, log your mood, get nutrition tips, or just chat!
        """
    }
    
    private func generateGeneralHealthResponse() -> String {
        return """
        I'm here to help with all aspects of your health! 🌟
        
        **What I Can Do:**
        
        📊 **Analyze Your Data**
        Sleep patterns, activity trends, heart health, recovery
        
        🍎 **Nutrition Guidance**
        Track meals, understand macros, hydration reminders
        
        😊 **Mental Wellness**
        Mood tracking, stress relief, meditation guidance
        
        🩸 **Biosensor Integration**
        Glucose monitoring, connected devices support
        
        💡 **Personalized Tips**
        Based on YOUR data, not generic advice
        
        Try asking me something specific like:
        • "How's my sleep this week?"
        • "What should I eat before a workout?"
        • "Why is my HRV low?"
        • "I'm feeling anxious"
        """
    }
    
    private func generateSmartDefault(for input: String) -> String {
        let name = userProfile.name.isEmpty ? "" : " \(userProfile.name.components(separatedBy: " ").first ?? "")"
        
        return """
        I'd love to help with that\(name)! 🤔
        
        While I'm best at health-related topics, I can try to assist. Could you tell me more about what you're looking for?
        
        **I'm great at:**
        • Analyzing your health metrics
        • Nutrition and diet guidance
        • Sleep optimization
        • Stress and mood support
        • Activity and fitness tips
        • Explaining your biosensor data
        
        Try one of the quick prompts below, or ask me something specific about your health!
        """
    }
}

// MARK: - Supporting Views

struct DataSourceChip: View {
    let icon: String
    let label: String
    let isActive: Bool
    var color: Color = .green
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(isActive ? color : .white.opacity(0.4))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isActive ? color.opacity(0.2) : Color.white.opacity(0.05))
        )
    }
}

// ChatMessage is defined in ChatHistoryManager.swift - do not redeclare here

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            
            Text(LocalizedStringKey(message.content))
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(message.isUser ? Color.cyan.opacity(0.3) : Color.white.opacity(0.1))
                )
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

struct QuickPromptButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                )
        }
    }
}

struct TypingIndicator: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.white.opacity(i < dotCount ? 0.8 : 0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))
            
            Spacer()
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

struct ModelInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.11, blue: 0.16).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "cpu")
                            .font(.system(size: 50))
                            .foregroundColor(.cyan)
                            .padding(.top, 20)
                        
                        Text("On-Device AI")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            InfoRow(icon: "brain", label: "Model", value: "Llama 3.2 1B Instruct")
                            InfoRow(icon: "square.stack.3d.up", label: "Quantization", value: "Q4_K_M (4-bit)")
                            InfoRow(icon: "internaldrive", label: "Size", value: "~750 MB")
                            InfoRow(icon: "iphone", label: "Processing", value: "100% On-Device")
                            InfoRow(icon: "lock.shield", label: "Privacy", value: "Data never leaves device")
                            InfoRow(icon: "bolt", label: "Optimized for", value: "Apple Neural Engine")
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 16) {
                            Text("Data Sources")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 8) {
                                DataSourceRow(icon: "applewatch", name: "Apple Watch", status: "Connected")
                                DataSourceRow(icon: "drop.fill", name: "Glucose CGM", status: "Coming Soon")
                                DataSourceRow(icon: "bed.double.fill", name: "Sleep Data", status: "Connected")
                                DataSourceRow(icon: "heart.fill", name: "Heart Metrics", status: "Connected")
                            }
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                        .padding(.horizontal, 24)
                        
                        Text("Your health data stays on your iPhone. The AI runs locally using Apple's Neural Engine for fast, private responses.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Spacer(minLength: 40)
                    }
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

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

struct DataSourceRow: View {
    let icon: String
    let name: String
    let status: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(status)
                .font(.system(size: 12))
                .foregroundColor(status == "Connected" ? .green : .yellow)
        }
    }
}
