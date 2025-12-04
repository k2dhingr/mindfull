import Foundation
import HealthKit
import Combine

// MARK: - Type Alias for compatibility
typealias HealthKitManager = HealthDataManager

@MainActor
class HealthDataManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    // Basic metrics (existing)
    @Published var stepCount: Int = 0
    @Published var sleepHours: Double = 0
    @Published var heartRate: Double = 0
    
    // Advanced metrics for AI
    @Published var heartRateVariability: Double = 0  // HRV - stress indicator
    @Published var restingHeartRate: Double = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var exerciseMinutes: Double = 0
    @Published var respiratoryRate: Double = 0
    @Published var oxygenSaturation: Double = 0
    @Published var standHours: Int = 0
    @Published var mindfulMinutes: Double = 0
    @Published var bodyTemperature: Double = 0
    
    // Workout data
    @Published var todaysWorkouts: [WorkoutData] = []
    
    // Authorization
    @Published var isAuthorized = false
    
    // MARK: - Property Aliases for Compatibility
    // These ensure both naming conventions work across all views
    
    var hrv: Double { heartRateVariability }
    var activeCalories: Double { activeEnergyBurned }
    
    // Batch update flag to prevent UI thrashing
    private var isBatchUpdating = false
    
    init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set<HKObjectType> = [
            // Existing
            HKQuantityType(.stepCount),
            HKQuantityType(.heartRate),
            HKCategoryType(.sleepAnalysis),
            
            // Critical for AI health insights
            HKQuantityType(.heartRateVariabilitySDNN),  // HRV - stress/recovery
            HKQuantityType(.restingHeartRate),          // Fitness level
            HKQuantityType(.activeEnergyBurned),        // Calorie expenditure
            HKQuantityType(.appleExerciseTime),         // Activity duration
            HKQuantityType(.respiratoryRate),           // Breathing health
            HKQuantityType(.oxygenSaturation),          // Blood oxygen
            HKQuantityType(.bodyTemperature),           // Fever detection
            HKQuantityType(.appleStandTime),            // Sedentary tracking
            
            // Mindfulness & Workouts
            HKCategoryType(.mindfulSession),
            HKWorkoutType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchTodayData()
                }
            }
        }
    }
    
    func fetchTodayData() {
        Task { @MainActor in
            isBatchUpdating = true
            
            // Fetch all data concurrently
            fetchSteps()
            fetchSleep()
            fetchHeartRate()
            fetchHeartRateVariability()
            fetchRestingHeartRate()
            
            // Fetch remaining metrics in background
            fetchActiveEnergy()
            fetchExerciseMinutes()
            fetchRespiratoryRate()
            fetchOxygenSaturation()
            fetchStandHours()
            fetchMindfulMinutes()
            fetchBodyTemperature()
            fetchWorkouts()
            
            isBatchUpdating = false
            objectWillChange.send()
        }
    }
    
    // MARK: - Existing Methods
    
    private func fetchSteps() {
        let stepType = HKQuantityType(.stepCount)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchSleep() {
        let sleepType = HKCategoryType(.sleepAnalysis)
        
        let now = Date()
        let startOfDay = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: now))!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            var totalSleep: TimeInterval = 0
            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            
            DispatchQueue.main.async {
                self.sleepHours = totalSleep / 3600
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeartRate() {
        let heartRateType = HKQuantityType(.heartRate)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                self.heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Advanced Health Metrics
    
    private func fetchHeartRateVariability() {
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }
            
            // Average the last 10 HRV readings for more stable value
            let avgHRV = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) } / Double(samples.count)
            
            DispatchQueue.main.async {
                self.heartRateVariability = avgHRV
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRestingHeartRate() {
        let restingHRType = HKQuantityType(.restingHeartRate)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: restingHRType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                self.restingHeartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveEnergy() {
        let energyType = HKQuantityType(.activeEnergyBurned)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.activeEnergyBurned = sum.doubleValue(for: HKUnit.kilocalorie())
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchExerciseMinutes() {
        let exerciseType = HKQuantityType(.appleExerciseTime)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: exerciseType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.exerciseMinutes = sum.doubleValue(for: HKUnit.minute())
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRespiratoryRate() {
        let respType = HKQuantityType(.respiratoryRate)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: respType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                self.respiratoryRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchOxygenSaturation() {
        let o2Type = HKQuantityType(.oxygenSaturation)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: o2Type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                self.oxygenSaturation = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchStandHours() {
        let standType = HKQuantityType(.appleStandTime)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: standType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.standHours = Int(sum.doubleValue(for: HKUnit.minute()) / 60)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchMindfulMinutes() {
        let mindfulType = HKCategoryType(.mindfulSession)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKSampleQuery(sampleType: mindfulType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            var totalMinutes: TimeInterval = 0
            for sample in samples {
                totalMinutes += sample.endDate.timeIntervalSince(sample.startDate)
            }
            
            DispatchQueue.main.async {
                self.mindfulMinutes = totalMinutes / 60
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBodyTemperature() {
        let tempType = HKQuantityType(.bodyTemperature)
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: tempType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                self.bodyTemperature = sample.quantity.doubleValue(for: HKUnit.degreeCelsius())
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWorkouts() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let workouts = samples as? [HKWorkout] else { return }
            
            let workoutData = workouts.map { workout in
                WorkoutData(
                    type: workout.workoutActivityType.name,
                    duration: workout.duration / 60, // minutes
                    calories: workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0,
                    date: workout.startDate
                )
            }
            
            DispatchQueue.main.async {
                self.todaysWorkouts = workoutData
            }
        }
        
        healthStore.execute(query)
    }
}

// MARK: - Supporting Types

struct WorkoutData: Identifiable {
    let id = UUID()
    let type: String
    let duration: Double // minutes
    let calories: Double
    let date: Date
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .hiking: return "Hiking"
        case .dance: return "Dance"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        default: return "Workout"
        }
    }
}

