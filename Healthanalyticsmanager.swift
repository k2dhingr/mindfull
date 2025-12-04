import Foundation
import CoreML
import Combine
import Accelerate

/// Health Analytics Manager - Uses REAL HealthKit data only
/// No random values, no fake predictions
class HealthAnalyticsManager: ObservableObject {
    @Published var currentHealthStatus: HealthStatus = .normal
    @Published var recentAnomalies: [HealthAnomaly] = []
    @Published var isAnalyzing = false
    
    // Real predictions based on actual data
    @Published var predictedEnergyLevel: Double = 0.0
    @Published var stressProbability: Double = 0.0
    @Published var sleepQualityScore: Double = 0.0
    @Published var burnoutRisk: BurnoutRisk = .low
    
    // Track if we have real data
    @Published var hasRealData: Bool = false
    
    private var baselineData: BaselineHealthData?
    
    init() {
        loadBaseline()
    }
    
    // MARK: - Main Analysis Function
    
    func analyzeHealthData(context: UnifiedHealthContext) {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        let health = context.healthData
        
        // Check if we have ANY real data
        hasRealData = health.stepCount > 0 || health.sleepHours > 0 || health.heartRate > 0
        
        guard hasRealData else {
            // No data - set everything to 0, not random values
            predictedEnergyLevel = 0
            stressProbability = 0
            sleepQualityScore = 0
            burnoutRisk = .low
            currentHealthStatus = .normal
            recentAnomalies = []
            return
        }
        
        // Update baseline with real data
        updateBaseline(with: context)
        
        // Calculate REAL predictions based on REAL data
        calculateEnergyLevel(context: context)
        calculateStressLevel(context: context)
        calculateSleepQuality(context: context)
        calculateBurnoutRisk(context: context)
        
        // Detect anomalies
        let detectedAnomalies = detectAnomalies(in: context)
        recentAnomalies = detectedAnomalies
        
        if !detectedAnomalies.isEmpty {
            currentHealthStatus = determineSeverity(from: detectedAnomalies)
        } else {
            currentHealthStatus = .normal
        }
        
        // Save baseline
        saveBaseline()
    }
    
    // MARK: - REAL Energy Calculation (No Random!)
    
    private func calculateEnergyLevel(context: UnifiedHealthContext) {
        let health = context.healthData
        var score: Double = 50.0  // Start at neutral
        var factors = 0
        
        // Sleep factor (most important for energy)
        if health.sleepHours > 0 {
            factors += 1
            if health.sleepHours >= 7 && health.sleepHours <= 9 {
                score += 25  // Optimal sleep
            } else if health.sleepHours >= 6 {
                score += 10  // Okay sleep
            } else if health.sleepHours >= 5 {
                score -= 10  // Poor sleep
            } else {
                score -= 25  // Very poor sleep
            }
        }
        
        // HRV factor (recovery indicator)
        if health.heartRateVariability > 0 {
            factors += 1
            if health.heartRateVariability > 50 {
                score += 15  // Good HRV
            } else if health.heartRateVariability > 35 {
                score += 5   // Moderate HRV
            } else {
                score -= 10  // Low HRV (stressed/tired)
            }
        }
        
        // Activity factor
        if health.stepCount > 0 {
            factors += 1
            if health.stepCount > 8000 {
                score += 10  // Active
            } else if health.stepCount > 5000 {
                score += 5   // Moderate activity
            } else if health.stepCount < 2000 {
                score -= 5   // Very sedentary
            }
        }
        
        // Resting HR factor
        if health.restingHeartRate > 0 {
            factors += 1
            if health.restingHeartRate < 60 {
                score += 10  // Athletic
            } else if health.restingHeartRate < 70 {
                score += 5   // Good
            } else if health.restingHeartRate > 80 {
                score -= 10  // Elevated (stress/fatigue)
            }
        }
        
        // Only set if we have actual data
        if factors > 0 {
            predictedEnergyLevel = min(max(score, 0), 100)
        } else {
            predictedEnergyLevel = 0
        }
    }
    
    // MARK: - REAL Stress Calculation (No Random!)
    
    private func calculateStressLevel(context: UnifiedHealthContext) {
        let health = context.healthData
        var stressScore: Double = 0.0
        var factors = 0
        
        // Low HRV = high stress
        if health.heartRateVariability > 0 {
            factors += 1
            if health.heartRateVariability < 30 {
                stressScore += 0.4  // High stress
            } else if health.heartRateVariability < 45 {
                stressScore += 0.2  // Moderate stress
            }
        }
        
        // Poor sleep = stress
        if health.sleepHours > 0 {
            factors += 1
            if health.sleepHours < 5 {
                stressScore += 0.3
            } else if health.sleepHours < 6 {
                stressScore += 0.15
            }
        }
        
        // Elevated resting HR = stress
        if health.restingHeartRate > 0 {
            factors += 1
            if health.restingHeartRate > 80 {
                stressScore += 0.2
            } else if health.restingHeartRate > 75 {
                stressScore += 0.1
            }
        }
        
        if factors > 0 {
            stressProbability = min(stressScore, 1.0)
        } else {
            stressProbability = 0
        }
    }
    
    // MARK: - REAL Sleep Quality (No Random!)
    
    private func calculateSleepQuality(context: UnifiedHealthContext) {
        let health = context.healthData
        
        guard health.sleepHours > 0 else {
            sleepQualityScore = 0
            return
        }
        
        var score: Double = 0
        
        // Duration score (0-50 points)
        if health.sleepHours >= 7 && health.sleepHours <= 9 {
            score += 50  // Optimal
        } else if health.sleepHours >= 6.5 {
            score += 40
        } else if health.sleepHours >= 6 {
            score += 30
        } else if health.sleepHours >= 5 {
            score += 20
        } else {
            score += 10
        }
        
        // HRV recovery bonus (0-30 points)
        if health.heartRateVariability > 50 {
            score += 30
        } else if health.heartRateVariability > 40 {
            score += 20
        } else if health.heartRateVariability > 30 {
            score += 10
        }
        
        // Low resting HR bonus (0-20 points)
        if health.restingHeartRate > 0 && health.restingHeartRate < 65 {
            score += 20
        } else if health.restingHeartRate > 0 && health.restingHeartRate < 75 {
            score += 10
        }
        
        sleepQualityScore = min(score, 100)
    }
    
    // MARK: - REAL Burnout Risk (No Random!)
    
    private func calculateBurnoutRisk(context: UnifiedHealthContext) {
        let health = context.healthData
        var riskFactors = 0
        
        // Check actual data indicators
        if health.sleepHours > 0 && health.sleepHours < 6 {
            riskFactors += 1
        }
        
        if health.heartRateVariability > 0 && health.heartRateVariability < 35 {
            riskFactors += 1
        }
        
        if health.restingHeartRate > 0 && health.restingHeartRate > 80 {
            riskFactors += 1
        }
        
        if stressProbability > 0.5 {
            riskFactors += 1
        }
        
        switch riskFactors {
        case 0...1:
            burnoutRisk = .low
        case 2:
            burnoutRisk = .moderate
        case 3:
            burnoutRisk = .high
        default:
            burnoutRisk = .critical
        }
    }
    
    // MARK: - Health Score (Deterministic!)
    
    func getHealthScore() -> Double {
        guard hasRealData else { return 0 }
        
        // Weighted combination of real metrics
        var score: Double = 0
        var totalWeight: Double = 0
        
        if predictedEnergyLevel > 0 {
            score += predictedEnergyLevel * 0.3
            totalWeight += 0.3
        }
        
        if sleepQualityScore > 0 {
            score += sleepQualityScore * 0.35
            totalWeight += 0.35
        }
        
        // Stress is inverted (low stress = high score)
        if stressProbability > 0 || hasRealData {
            score += (1.0 - stressProbability) * 100 * 0.2
            totalWeight += 0.2
        }
        
        // Burnout risk contribution
        let burnoutScore: Double
        switch burnoutRisk {
        case .low: burnoutScore = 100
        case .moderate: burnoutScore = 60
        case .high: burnoutScore = 30
        case .critical: burnoutScore = 10
        }
        score += burnoutScore * 0.15
        totalWeight += 0.15
        
        return totalWeight > 0 ? score / totalWeight : 0
    }
    
    // MARK: - Anomaly Detection
    
    private func detectAnomalies(in context: UnifiedHealthContext) -> [HealthAnomaly] {
        let health = context.healthData
        var anomalies: [HealthAnomaly] = []
        
        // Only detect anomalies if we have real data
        
        // Very low sleep
        if health.sleepHours > 0 && health.sleepHours < 5 {
            anomalies.append(HealthAnomaly(
                type: .sleepDeficit,
                severity: health.sleepHours < 4 ? .critical : .warning,
                message: "Sleep critically low at \(String(format: "%.1f", health.sleepHours)) hours. Prioritize rest tonight.",
                currentValue: health.sleepHours,
                baselineValue: 7.5,
                detectedAt: Date(),
                mlConfidence: 0.95
            ))
        }
        
        // Very low HRV
        if health.heartRateVariability > 0 && health.heartRateVariability < 30 {
            anomalies.append(HealthAnomaly(
                type: .hrvAnomaly,
                severity: .warning,
                message: "HRV is low (\(Int(health.heartRateVariability))ms). This indicates stress or fatigue. Consider rest.",
                currentValue: health.heartRateVariability,
                baselineValue: 50,
                detectedAt: Date(),
                mlConfidence: 0.85
            ))
        }
        
        // Elevated resting HR
        if health.restingHeartRate > 85 {
            anomalies.append(HealthAnomaly(
                type: .heartRateAnomaly,
                severity: health.restingHeartRate > 95 ? .critical : .warning,
                message: "Resting heart rate elevated (\(Int(health.restingHeartRate)) bpm). May indicate stress, dehydration, or illness.",
                currentValue: health.restingHeartRate,
                baselineValue: 65,
                detectedAt: Date(),
                mlConfidence: 0.88
            ))
        }
        
        // Low blood oxygen
        if health.oxygenSaturation > 0 && health.oxygenSaturation < 95 {
            anomalies.append(HealthAnomaly(
                type: .oxygenAnomaly,
                severity: health.oxygenSaturation < 92 ? .critical : .warning,
                message: "Blood oxygen at \(Int(health.oxygenSaturation))%. Normal is 95-100%. Consult doctor if persistent.",
                currentValue: health.oxygenSaturation,
                baselineValue: 98,
                detectedAt: Date(),
                mlConfidence: 0.92
            ))
        }
        
        return anomalies
    }
    
    private func determineSeverity(from anomalies: [HealthAnomaly]) -> HealthStatus {
        if anomalies.contains(where: { $0.severity == .critical }) {
            return .critical
        } else if anomalies.contains(where: { $0.severity == .warning }) {
            return .warning
        } else if !anomalies.isEmpty {
            return .info
        }
        return .normal
    }
    
    // MARK: - Baseline Management
    
    private func updateBaseline(with context: UnifiedHealthContext) {
        let health = context.healthData
        
        if baselineData == nil {
            baselineData = BaselineHealthData(
                avgSteps: health.stepCount,
                avgSleepHours: health.sleepHours,
                avgRestingHR: health.restingHeartRate,
                avgHRV: health.heartRateVariability,
                sampleCount: 1,
                lastUpdated: Date()
            )
        } else {
            let alpha = 0.2
            
            if health.stepCount > 0 {
                baselineData!.avgSteps = alpha * health.stepCount + (1 - alpha) * baselineData!.avgSteps
            }
            if health.sleepHours > 0 {
                baselineData!.avgSleepHours = alpha * health.sleepHours + (1 - alpha) * baselineData!.avgSleepHours
            }
            if health.restingHeartRate > 0 {
                baselineData!.avgRestingHR = alpha * health.restingHeartRate + (1 - alpha) * baselineData!.avgRestingHR
            }
            if health.heartRateVariability > 0 {
                baselineData!.avgHRV = alpha * health.heartRateVariability + (1 - alpha) * baselineData!.avgHRV
            }
            
            baselineData!.sampleCount += 1
            baselineData!.lastUpdated = Date()
        }
    }
    
    private func saveBaseline() {
        guard let baseline = baselineData else { return }
        
        do {
            let data = try JSONEncoder().encode(baseline)
            UserDefaults.standard.set(data, forKey: "health_baseline_v2")
        } catch {
            print("❌ Failed to save baseline: \(error)")
        }
    }
    
    private func loadBaseline() {
        guard let data = UserDefaults.standard.data(forKey: "health_baseline_v2") else { return }
        
        do {
            baselineData = try JSONDecoder().decode(BaselineHealthData.self, from: data)
            print("✅ Loaded baseline (\(baselineData!.sampleCount) samples)")
        } catch {
            print("❌ Failed to load baseline: \(error)")
        }
    }
    
    /// Clear all stored data and reset
    func resetAllData() {
        baselineData = nil
        predictedEnergyLevel = 0
        stressProbability = 0
        sleepQualityScore = 0
        burnoutRisk = .low
        hasRealData = false
        currentHealthStatus = .normal
        recentAnomalies = []
        
        UserDefaults.standard.removeObject(forKey: "health_baseline_v2")
        print("🗑️ Reset all health analytics data")
    }
}

// MARK: - Supporting Types

struct BaselineHealthData: Codable {
    var avgSteps: Double
    var avgSleepHours: Double
    var avgRestingHR: Double
    var avgHRV: Double
    var sampleCount: Int
    var lastUpdated: Date
}

enum HealthStatus: String {
    case normal
    case info
    case warning
    case critical
    
    var displayName: String {
        switch self {
        case .normal: return "All Good"
        case .info: return "Info"
        case .warning: return "Attention Needed"
        case .critical: return "Critical Alert"
        }
    }
}

enum BurnoutRisk: String {
    case low
    case moderate
    case high
    case critical
    
    var displayName: String {
        rawValue.capitalized
    }
}

struct HealthAnomaly: Identifiable {
    let id = UUID()
    let type: AnomalyType
    let severity: AnomalySeverity
    let message: String
    let currentValue: Double
    let baselineValue: Double
    let detectedAt: Date
    let mlConfidence: Double
}

enum AnomalyType {
    case sleepDeficit
    case hrvAnomaly
    case heartRateAnomaly
    case activityDrop
    case oxygenAnomaly
    case temperatureAnomaly
    case compoundStress
    case burnoutRisk
    
    var displayName: String {
        switch self {
        case .sleepDeficit: return "Sleep Deficit"
        case .hrvAnomaly: return "HRV Anomaly"
        case .heartRateAnomaly: return "Heart Rate"
        case .activityDrop: return "Activity Drop"
        case .oxygenAnomaly: return "Blood Oxygen"
        case .temperatureAnomaly: return "Temperature"
        case .compoundStress: return "Compound Stress"
        case .burnoutRisk: return "Burnout Risk"
        }
    }
}

enum AnomalySeverity: Int {
    case info = 1
    case warning = 2
    case critical = 3
    
    var displayName: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}
