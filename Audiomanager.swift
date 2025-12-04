import Foundation
import AVFoundation
import UIKit
import Combine

// MARK: - AudioManager
// Handles all audio playback for meditation and breathing exercises

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published var isPlaying = false
    @Published var currentSound: SoundType?
    
    private var audioPlayer: AVAudioPlayer?
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    // Haptic feedback generators
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    enum SoundType: String {
        case meditationBell = "meditation_bell"
        case breatheIn = "breathe_in"
        case breatheOut = "breathe_out"
        case complete = "complete"
        case ambient = "ambient"
        case chime = "chime"
    }
    
    init() {
        setupAudioSession()
        impactGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Play Sound
    
    func playSound(_ type: SoundType, volume: Float = 1.0) {
        // First try to load from bundle
        if let url = Bundle.main.url(forResource: type.rawValue, withExtension: "mp3") {
            playFromURL(url, volume: volume)
            currentSound = type
            return
        }
        
        // Try .wav extension
        if let url = Bundle.main.url(forResource: type.rawValue, withExtension: "wav") {
            playFromURL(url, volume: volume)
            currentSound = type
            return
        }
        
        // Try .m4a extension
        if let url = Bundle.main.url(forResource: type.rawValue, withExtension: "m4a") {
            playFromURL(url, volume: volume)
            currentSound = type
            return
        }
        
        // Fallback: Use system sounds + haptics
        print("⚠️ Sound file '\(type.rawValue)' not found, using haptic feedback")
        playHapticFeedback(for: type)
    }
    
    private func playFromURL(_ url: URL, volume: Float) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            print("🔊 Playing sound: \(url.lastPathComponent)")
        } catch {
            print("❌ Error playing sound: \(error)")
            // Fallback to haptic
            impactGenerator.impactOccurred()
        }
    }
    
    // MARK: - Haptic Feedback (Fallback when no audio files)
    
    func playHapticFeedback(for type: SoundType) {
        switch type {
        case .meditationBell, .complete, .chime:
            // Strong notification-style feedback
            notificationGenerator.notificationOccurred(.success)
            
            // Double tap for emphasis
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.impactGenerator.impactOccurred(intensity: 0.7)
            }
            
        case .breatheIn:
            // Gentle ramp up
            impactGenerator.impactOccurred(intensity: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.impactGenerator.impactOccurred(intensity: 0.5)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.impactGenerator.impactOccurred(intensity: 0.7)
            }
            
        case .breatheOut:
            // Gentle ramp down
            impactGenerator.impactOccurred(intensity: 0.7)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.impactGenerator.impactOccurred(intensity: 0.4)
            }
            
        case .ambient:
            // Soft periodic feedback
            impactGenerator.impactOccurred(intensity: 0.2)
        }
    }
    
    // MARK: - Background Music
    
    func playBackgroundMusic(_ type: SoundType, volume: Float = 0.3) {
        guard let url = Bundle.main.url(forResource: type.rawValue, withExtension: "mp3") else {
            print("⚠️ Background music '\(type.rawValue)' not found")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.volume = volume
            backgroundMusicPlayer?.numberOfLoops = -1  // Loop indefinitely
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
        } catch {
            print("❌ Error playing background music: \(error)")
        }
    }
    
    func stopBackgroundMusic(fadeOut: Bool = true) {
        if fadeOut {
            fadeOutBackgroundMusic()
        } else {
            backgroundMusicPlayer?.stop()
            backgroundMusicPlayer = nil
        }
    }
    
    private func fadeOutBackgroundMusic() {
        guard let player = backgroundMusicPlayer else { return }
        
        let fadeSteps = 10
        let fadeInterval = 0.1
        let volumeStep = player.volume / Float(fadeSteps)
        
        for i in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * fadeInterval) {
                player.volume -= volumeStep
                if i == fadeSteps - 1 {
                    player.stop()
                    self.backgroundMusicPlayer = nil
                }
            }
        }
    }
    
    // MARK: - Stop
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentSound = nil
    }
    
    func stopAll() {
        stop()
        stopBackgroundMusic(fadeOut: false)
    }
    
    // MARK: - Breathing Exercise Sounds
    
    func playBreathingCue(phase: BreathingPhase) {
        switch phase {
        case .inhale:
            playSound(.breatheIn, volume: 0.6)
            playHapticFeedback(for: .breatheIn)
            
        case .hold:
            // Gentle haptic to indicate hold
            impactGenerator.impactOccurred(intensity: 0.3)
            
        case .exhale:
            playSound(.breatheOut, volume: 0.6)
            playHapticFeedback(for: .breatheOut)
            
        case .rest:
            // Very soft haptic
            impactGenerator.impactOccurred(intensity: 0.2)
        }
    }
    
    // MARK: - Meditation Sounds
    
    func playMeditationStart() {
        playSound(.meditationBell, volume: 0.7)
    }
    
    func playMeditationEnd() {
        playSound(.meditationBell, volume: 0.8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.playSound(.complete, volume: 0.6)
        }
    }
    
    func playSessionComplete() {
        notificationGenerator.notificationOccurred(.success)
        playSound(.complete, volume: 0.8)
    }
}

// MARK: - Breathing Phase

enum BreathingPhase: String {
    case inhale = "Breathe In"
    case hold = "Hold"
    case exhale = "Breathe Out"
    case rest = "Rest"
    
    var color: String {
        switch self {
        case .inhale: return "blue"
        case .hold: return "purple"
        case .exhale: return "green"
        case .rest: return "gray"
        }
    }
}

// MARK: - Synthesized Sounds (No external files needed!)

extension AudioManager {
    
    /// Generate a simple bell/chime sound using AVAudioEngine
    /// This works without any external audio files
    func playSynthesizedBell() {
        // Use system sound as fallback
        AudioServicesPlaySystemSound(1057)  // System chime sound
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Play a sequence of haptics that feels like breathing guidance
    func playBreathingHapticSequence(inhaleSeconds: Int, holdSeconds: Int, exhaleSeconds: Int) {
        var delay: Double = 0
        
        // Inhale - gradual increasing intensity
        for i in 0..<inhaleSeconds {
            let intensity = 0.3 + (0.5 * Double(i) / Double(inhaleSeconds))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.impactGenerator.impactOccurred(intensity: CGFloat(intensity))
            }
            delay += 1.0
        }
        
        // Hold - steady light taps
        for _ in 0..<holdSeconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.impactGenerator.impactOccurred(intensity: 0.3)
            }
            delay += 1.0
        }
        
        // Exhale - gradual decreasing intensity
        for i in 0..<exhaleSeconds {
            let intensity = 0.8 - (0.5 * Double(i) / Double(exhaleSeconds))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.impactGenerator.impactOccurred(intensity: CGFloat(intensity))
            }
            delay += 1.0
        }
    }
}
