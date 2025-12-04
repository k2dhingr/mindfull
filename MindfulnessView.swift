import SwiftUI
import HealthKit
import Combine

// MARK: - Mood Manager for Data Persistence
@MainActor
class MoodManager: ObservableObject {
    @Published var moodHistory: [MoodEntry] = []
    
    private let storageKey = "mood_history"
    private let healthStore = HKHealthStore()
    
    init() {
        loadMoodHistory()
    }
    
    func saveMood(mood: String, label: String, note: String) {
        let entry = MoodEntry(mood: mood, label: label, note: note, timestamp: Date())
        moodHistory.insert(entry, at: 0)
        
        // Keep only last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        moodHistory = moodHistory.filter { $0.timestamp > thirtyDaysAgo }
        
        saveMoodHistory()
    }
    
    private func saveMoodHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(moodHistory)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save mood history: \(error)")
        }
    }
    
    private func loadMoodHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            moodHistory = try decoder.decode([MoodEntry].self, from: data)
        } catch {
            print("❌ Failed to load mood history: \(error)")
        }
    }
}

struct MoodEntry: Identifiable, Codable {
    let id: UUID
    let mood: String
    let label: String
    let note: String
    let timestamp: Date
    
    init(mood: String, label: String, note: String, timestamp: Date) {
        self.id = UUID()
        self.mood = mood
        self.label = label
        self.note = note
        self.timestamp = timestamp
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

struct MindfulnessView: View {
    @StateObject private var moodManager = MoodManager()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
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
                    // Custom segmented control
                    HStack(spacing: 0) {
                        ForEach(["Meditate", "Breathe", "Mood"], id: \.self) { tab in
                            Button(action: {
                                withAnimation {
                                    selectedTab = tab == "Meditate" ? 0 : tab == "Breathe" ? 1 : 2
                                }
                            }) {
                                Text(tab)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(selectedTab == (tab == "Meditate" ? 0 : tab == "Breathe" ? 1 : 2) ? .white : .white.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedTab == (tab == "Meditate" ? 0 : tab == "Breathe" ? 1 : 2) ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    TabView(selection: $selectedTab) {
                        MeditationTab()
                            .tag(0)
                        
                        BreathingTab()
                            .tag(1)
                        
                        MoodTab(moodManager: moodManager)
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Mindfulness")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Meditation Tab

struct MeditationTab: View {
    let meditations = [
        Meditation(title: "Sleep Better", duration: 10, category: "Sleep", icon: "moon.stars.fill"),
        Meditation(title: "Stress Relief", duration: 5, category: "Stress", icon: "wind"),
        Meditation(title: "Focus & Clarity", duration: 7, category: "Focus", icon: "brain.head.profile"),
        Meditation(title: "Morning Energy", duration: 5, category: "Energy", icon: "sunrise.fill"),
        Meditation(title: "Gratitude Practice", duration: 8, category: "Wellness", icon: "heart.fill"),
        Meditation(title: "Body Scan", duration: 15, category: "Relaxation", icon: "figure.mind.and.body")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(meditations) { meditation in
                    MeditationCard(meditation: meditation)
                }
            }
            .padding(20)
        }
    }
}

struct Meditation: Identifiable {
    let id = UUID()
    let title: String
    let duration: Int
    let category: String
    let icon: String
}

struct MeditationCard: View {
    let meditation: Meditation
    @State private var showMeditation = false
    
    var body: some View {
        Button(action: { showMeditation = true }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: meditation.icon)
                        .font(.system(size: 26))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(meditation.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(meditation.category)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text("\(meditation.duration) min")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .sheet(isPresented: $showMeditation) {
            MeditationPlayerView(meditation: meditation)
        }
    }
}

// MARK: - Meditation Player with Audio

struct MeditationPlayerView: View {
    @Environment(\.dismiss) var dismiss
    let meditation: Meditation
    
    @State private var progress: Double = 0
    @State private var isPlaying = false
    @State private var timer: Timer?
    @State private var startTime: Date?
    @State private var elapsedSeconds: Int = 0
    @State private var showComplete = false
    
    @StateObject private var audioManager = AudioManager.shared
    private let healthStore = HKHealthStore()
    
    var totalSeconds: Int {
        meditation.duration * 60
    }
    
    var remainingTime: String {
        let remaining = totalSeconds - elapsedSeconds
        let mins = remaining / 60
        let secs = remaining % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated icon
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.3), lineWidth: 2)
                        .frame(width: 180, height: 180)
                        .scaleEffect(isPlaying ? 1.2 : 1.0)
                        .opacity(isPlaying ? 0 : 1)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: isPlaying)
                    
                    // Inner circle
                    Circle()
                        .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.2))
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: meditation.icon)
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
                .scaleEffect(isPlaying ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isPlaying)
                
                VStack(spacing: 12) {
                    Text(meditation.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(remainingTime)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .monospacedDigit()
                }
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color(red: 0.4, green: 0.8, blue: 0.6),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)
                    
                    // Play/Pause button in center
                    Button(action: togglePlay) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Bottom controls
                HStack(spacing: 40) {
                    Button(action: {
                        timer?.invalidate()
                        audioManager.stopAll()
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 28))
                            Text("End")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Button(action: {
                        // Skip forward 30 seconds
                        elapsedSeconds = min(elapsedSeconds + 30, totalSeconds)
                        progress = Double(elapsedSeconds) / Double(totalSeconds)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "goforward.30")
                                .font(.system(size: 28))
                            Text("Skip")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 40)
            }
            
            // Completion overlay
            if showComplete {
                CompletionOverlay(
                    title: "Well Done! 🧘",
                    subtitle: "You completed \(meditation.duration) minutes of meditation",
                    onDismiss: { dismiss() }
                )
            }
        }
        .onAppear {
            // Play starting bell
            audioManager.playMeditationStart()
        }
        .onDisappear {
            timer?.invalidate()
            audioManager.stopAll()
        }
    }
    
    func togglePlay() {
        isPlaying.toggle()
        
        if isPlaying {
            startTime = Date()
            
            // Play ambient sound
            audioManager.playBackgroundMusic(.ambient, volume: 0.2)
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if elapsedSeconds < totalSeconds {
                    elapsedSeconds += 1
                    progress = Double(elapsedSeconds) / Double(totalSeconds)
                } else {
                    timer?.invalidate()
                    isPlaying = false
                    audioManager.playMeditationEnd()
                    saveMindfulSession()
                    showComplete = true
                }
            }
        } else {
            timer?.invalidate()
            audioManager.stopBackgroundMusic()
        }
    }
    
    func saveMindfulSession() {
        guard let start = startTime else { return }
        
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let end = Date()
        
        let mindfulSample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )
        
        healthStore.save(mindfulSample) { success, error in
            if success {
                print("✅ Saved \(meditation.duration) min meditation to HealthKit")
            } else if let error = error {
                print("❌ Failed to save meditation: \(error)")
            }
        }
    }
}

// MARK: - Breathing Tab

struct BreathingTab: View {
    let exercises = [
        BreathingExercise(name: "4-7-8 Relaxing", inhale: 4, hold: 7, exhale: 8, benefit: "Reduces anxiety and promotes sleep"),
        BreathingExercise(name: "Box Breathing", inhale: 4, hold: 4, exhale: 4, benefit: "Improves focus and reduces stress"),
        BreathingExercise(name: "Energizing Breath", inhale: 6, hold: 0, exhale: 2, benefit: "Increases energy and alertness"),
        BreathingExercise(name: "Calm Breath", inhale: 4, hold: 2, exhale: 6, benefit: "Activates parasympathetic nervous system")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(exercises) { exercise in
                    BreathingCard(exercise: exercise)
                }
            }
            .padding(20)
        }
    }
}

struct BreathingExercise: Identifiable {
    let id = UUID()
    let name: String
    let inhale: Int
    let hold: Int
    let exhale: Int
    let benefit: String
}

struct BreathingCard: View {
    let exercise: BreathingExercise
    @State private var showExercise = false
    
    var body: some View {
        Button(action: { showExercise = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(exercise.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
                
                Text(exercise.benefit)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 16) {
                    Label("\(exercise.inhale)s inhale", systemImage: "arrow.down.circle")
                    if exercise.hold > 0 {
                        Label("\(exercise.hold)s hold", systemImage: "pause.circle")
                    }
                    Label("\(exercise.exhale)s exhale", systemImage: "arrow.up.circle")
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .sheet(isPresented: $showExercise) {
            BreathingExerciseView(exercise: exercise)
        }
    }
}

// MARK: - Breathing Exercise with Audio

struct BreathingExerciseView: View {
    @Environment(\.dismiss) var dismiss
    let exercise: BreathingExercise
    
    @State private var phase: BreathingPhase = .inhale
    @State private var countdown: Int = 4
    @State private var isActive = false
    @State private var scale: CGFloat = 1.0
    @State private var cycleCount = 0
    @State private var showComplete = false
    
    @StateObject private var audioManager = AudioManager.shared
    
    let targetCycles = 5
    
    var phaseColor: Color {
        switch phase {
        case .inhale: return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .hold: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .exhale: return Color(red: 0.4, green: 0.8, blue: 0.6)
        case .rest: return Color.gray
        }
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.3),
                    Color(red: 0.15, green: 0.25, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Cycle \(cycleCount + 1) of \(targetCycles)")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Breathing circle
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(phaseColor.opacity(0.1))
                        .frame(width: 300, height: 300)
                        .scaleEffect(scale * 1.1)
                        .blur(radius: 20)
                    
                    // Main circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [phaseColor.opacity(0.6), phaseColor.opacity(0.2)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 250, height: 250)
                        .scaleEffect(scale)
                    
                    // Inner content
                    VStack(spacing: 16) {
                        Text(phase.rawValue)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(countdown)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                }
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 40) {
                    Button(action: {
                        stopExercise()
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                            Text("End")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Button(action: {
                        isActive ? stopExercise() : startExercise()
                    }) {
                        ZStack {
                            Circle()
                                .fill(phaseColor)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: isActive ? "pause.fill" : "play.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Button(action: {
                        // Skip to next phase
                        countdown = 0
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 32))
                            Text("Skip")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 60)
            }
            
            // Completion overlay
            if showComplete {
                CompletionOverlay(
                    title: "Great Job! 🌬️",
                    subtitle: "You completed \(targetCycles) breathing cycles",
                    onDismiss: { dismiss() }
                )
            }
        }
        .onAppear {
            countdown = exercise.inhale
        }
        .onDisappear {
            stopExercise()
        }
    }
    
    func startExercise() {
        isActive = true
        audioManager.playSynthesizedBell()
        runCycle()
    }
    
    func stopExercise() {
        isActive = false
        audioManager.stopAll()
    }
    
    func runCycle() {
        guard isActive else { return }
        
        // Check if completed all cycles
        if cycleCount >= targetCycles {
            audioManager.playSessionComplete()
            showComplete = true
            return
        }
        
        // Inhale phase
        phase = .inhale
        countdown = exercise.inhale
        audioManager.playBreathingCue(phase: .inhale)
        
        withAnimation(.easeInOut(duration: Double(exercise.inhale))) {
            scale = 1.5
        }
        
        runCountdown(duration: exercise.inhale) {
            guard isActive else { return }
            
            // Hold phase (if any)
            if exercise.hold > 0 {
                phase = .hold
                countdown = exercise.hold
                audioManager.playBreathingCue(phase: .hold)
                
                runCountdown(duration: exercise.hold) {
                    startExhale()
                }
            } else {
                startExhale()
            }
        }
    }
    
    func startExhale() {
        guard isActive else { return }
        
        phase = .exhale
        countdown = exercise.exhale
        audioManager.playBreathingCue(phase: .exhale)
        
        withAnimation(.easeInOut(duration: Double(exercise.exhale))) {
            scale = 1.0
        }
        
        runCountdown(duration: exercise.exhale) {
            cycleCount += 1
            runCycle()
        }
    }
    
    func runCountdown(duration: Int, completion: @escaping () -> Void) {
        guard isActive else { return }
        
        if countdown > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard isActive else { return }
                countdown -= 1
                runCountdown(duration: duration, completion: completion)
            }
        } else {
            completion()
        }
    }
}

// MARK: - Completion Overlay

struct CompletionOverlay: View {
    let title: String
    let subtitle: String
    let onDismiss: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button(action: onDismiss) {
                    Text("Done")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 160, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                        )
                }
                .padding(.top, 16)
            }
            .padding(40)
            .scaleEffect(showContent ? 1 : 0.5)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
}

// MARK: - Mood Tab

struct MoodTab: View {
    @ObservedObject var moodManager: MoodManager
    @State private var selectedMood: String = ""
    @State private var selectedMoodLabel: String = ""
    @State private var moodNote: String = ""
    @State private var showSaved = false
    @State private var showHistory = false
    @FocusState private var isNoteFieldFocused: Bool
    
    let moods = ["😊", "😌", "😐", "😰", "😡"]
    let moodLabels = ["Great", "Good", "Okay", "Anxious", "Angry"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("How are you feeling?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ForEach(Array(moods.enumerated()), id: \.offset) { index, mood in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    selectedMood = mood
                                    selectedMoodLabel = moodLabels[index]
                                }
                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                Text(mood)
                                    .font(.system(size: 44))
                                    .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                                    .opacity(selectedMood.isEmpty || selectedMood == mood ? 1.0 : 0.4)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if !selectedMoodLabel.isEmpty {
                        Text(selectedMoodLabel)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                
                // Note field
                if !selectedMood.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add a note (optional)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("What's on your mind?", text: $moodNote, axis: .vertical)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(16)
                            .lineLimit(3...5)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.1))
                            )
                            .focused($isNoteFieldFocused)
                        
                        Button(action: saveMood) {
                            Text("Save Mood")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 26)
                                        .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                                )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Recent moods
                if !moodManager.moodHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Moods")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("See All") {
                                showHistory = true
                            }
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                        }
                        
                        ForEach(moodManager.moodHistory.prefix(3)) { entry in
                            MoodHistoryRow(entry: entry)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            .padding(20)
        }
        .onTapGesture {
            isNoteFieldFocused = false
        }
        .alert("Mood Saved!", isPresented: $showSaved) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $showHistory) {
            MoodHistoryView(moodManager: moodManager)
        }
    }
    
    func saveMood() {
        guard !selectedMood.isEmpty else { return }
        
        moodManager.saveMood(mood: selectedMood, label: selectedMoodLabel, note: moodNote)
        
        // Reset
        selectedMood = ""
        selectedMoodLabel = ""
        moodNote = ""
        isNoteFieldFocused = false
        
        // Haptic and visual feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        showSaved = true
    }
}

struct MoodHistoryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        HStack(spacing: 16) {
            Text(entry.mood)
                .font(.system(size: 32))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(entry.formattedDate)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            if !entry.note.isEmpty {
                Image(systemName: "note.text")
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
    }
}

struct MoodHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var moodManager: MoodManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.1, green: 0.2, blue: 0.3).ignoresSafeArea()
                
                if moodManager.moodHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No moods logged yet")
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(moodManager.moodHistory) { entry in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 16) {
                                        Text(entry.mood)
                                            .font(.system(size: 40))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.label)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            Text(entry.formattedDate)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    if !entry.note.isEmpty {
                                        Text(entry.note)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.leading, 56)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Mood History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MindfulnessView()
}

