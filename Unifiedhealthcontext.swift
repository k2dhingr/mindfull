import Foundation
import SwiftUI

/// Unified context that aggregates ALL data for AI
/// This is what gets fed to Llama for personalized responses
struct UnifiedHealthContext {
    
    // MARK: - Data Sources
    
    var healthData: HealthDataSnapshot
    var userProfile: UserProfileSnapshot
    var nutritionData: NutritionSnapshot
    var mindfulnessData: MindfulnessSnapshot
    var temporalContext: TemporalContext
    
    init(
        healthManager: HealthDataManager,
        userProfile: UserProfile,
        nutritionManager: NutritionManager
    ) {
        // Capture health data
        self.healthData = HealthDataSnapshot(from: healthManager)
        
        // Capture user profile
        self.userProfile = UserProfileSnapshot(from: userProfile)
        
        // Capture nutrition data
        self.nutritionData = NutritionSnapshot(from: nutritionManager)
        
        // Capture mindfulness data (placeholder for now)
        self.mindfulnessData = MindfulnessSnapshot()
        
        // Capture temporal context
        self.temporalContext = TemporalContext()
    }
    
    // MARK: - Generate Context String for AI
    
    func generateContextString() -> String {
        var context = """
        === USER HEALTH CONTEXT ===
        
        HealthKit Data:
        """
        
        // Health metrics
        context += "\n• Steps: \(Int(healthData.stepCount)) (goal: \(userProfile.dailyStepGoal))"
        context += "\n• Sleep: \(String(format: "%.1f", healthData.sleepHours))h (goal: \(String(format: "%.1f", userProfile.sleepGoalHours))h)"
        context += "\n• Heart Rate: \(Int(healthData.heartRate)) bpm"
        
        if healthData.heartRateVariability > 0 {
            context += "\n• HRV: \(Int(healthData.heartRateVariability))ms"
        }
        
        if healthData.restingHeartRate > 0 {
            context += "\n• Resting HR: \(Int(healthData.restingHeartRate)) bpm"
        }
        
        if healthData.activeEnergyBurned > 0 {
            context += "\n• Active Calories: \(Int(healthData.activeEnergyBurned)) kcal"
        }
        
        if healthData.exerciseMinutes > 0 {
            context += "\n• Exercise: \(Int(healthData.exerciseMinutes)) mins"
        }
        
        if healthData.standHours > 0 {
            context += "\n• Stand Hours: \(healthData.standHours)/12"
        }
        
        if healthData.mindfulMinutes > 0 {
            context += "\n• Mindful Minutes: \(Int(healthData.mindfulMinutes))"
        }
        
        if healthData.oxygenSaturation > 0 {
            context += "\n• Blood Oxygen: \(Int(healthData.oxygenSaturation))%"
        }
        
        if healthData.respiratoryRate > 0 {
            context += "\n• Respiratory Rate: \(Int(healthData.respiratoryRate)) br/min"
        }
        
        // Workouts
        if !healthData.workouts.isEmpty {
            context += "\n\nWorkouts Today:"
            for workout in healthData.workouts.prefix(3) {
                context += "\n• \(workout.type): \(Int(workout.duration))min, \(Int(workout.calories))cal"
            }
        }
        
        // User profile
        context += """
        
        
        User Profile:
        • Name: \(userProfile.name)
        • Age: \(userProfile.age), Gender: \(userProfile.gender)
        • Height: \(Int(userProfile.heightCm))cm, Weight: \(Int(userProfile.weightKg))kg
        • BMI: \(String(format: "%.1f", userProfile.bmi)) (\(userProfile.bmiCategory))
        • BMR: \(Int(userProfile.bmr)) cal/day
        """
        
        // Nutrition
        context += """
        
        
        Nutrition Today:
        • Calories: \(nutritionData.totalCalories)/\(userProfile.dailyCalorieGoal)
        • Protein: \(Int(nutritionData.totalProtein))g
        • Carbs: \(Int(nutritionData.totalCarbs))g
        • Fat: \(Int(nutritionData.totalFat))g
        • Water: \(nutritionData.waterIntake)ml/2000ml
        """
        
        if !nutritionData.recentMeals.isEmpty {
            context += "\n\nRecent Meals:"
            for meal in nutritionData.recentMeals.prefix(3) {
                context += "\n• \(meal.name): \(meal.calories)cal"
            }
        }
        
        // Temporal context
        context += """
        
        
        Time Context:
        • Current time: \(temporalContext.timeOfDay)
        • Day: \(temporalContext.dayOfWeek)
        • Part of day: \(temporalContext.partOfDay)
        """
        
        context += "\n\n==========================="
        
        return context
    }
}

// MARK: - Snapshot Structures

struct HealthDataSnapshot {
    let stepCount: Double
    let sleepHours: Double
    let heartRate: Double
    let heartRateVariability: Double
    let restingHeartRate: Double
    let activeEnergyBurned: Double
    let exerciseMinutes: Double
    let respiratoryRate: Double
    let oxygenSaturation: Double
    let standHours: Int
    let mindfulMinutes: Double
    let bodyTemperature: Double
    let workouts: [WorkoutSnapshot]
    
    init(from manager: HealthDataManager) {
        // Convert Int stepCount to Double for this snapshot
        self.stepCount = Double(manager.stepCount)
        self.sleepHours = manager.sleepHours
        self.heartRate = manager.heartRate
        self.heartRateVariability = manager.heartRateVariability
        self.restingHeartRate = manager.restingHeartRate
        self.activeEnergyBurned = manager.activeEnergyBurned
        self.exerciseMinutes = manager.exerciseMinutes
        self.respiratoryRate = manager.respiratoryRate
        self.oxygenSaturation = manager.oxygenSaturation
        self.standHours = manager.standHours
        self.mindfulMinutes = manager.mindfulMinutes
        self.bodyTemperature = manager.bodyTemperature
        self.workouts = manager.todaysWorkouts.map { WorkoutSnapshot(from: $0) }
    }
}

struct WorkoutSnapshot {
    let type: String
    let duration: Double
    let calories: Double
    
    init(from workout: WorkoutData) {
        self.type = workout.type
        self.duration = workout.duration
        self.calories = workout.calories
    }
}

struct UserProfileSnapshot {
    let name: String
    let age: Int
    let gender: String
    let heightCm: Double
    let weightKg: Double
    let bmi: Double
    let bmiCategory: String
    let bmr: Double
    let dailyStepGoal: Int
    let dailyCalorieGoal: Int
    let sleepGoalHours: Double
    let weeklyWorkoutGoal: Int
    
    init(from profile: UserProfile) {
        self.name = profile.name
        self.age = profile.age
        self.gender = profile.gender
        self.heightCm = profile.heightCm
        self.weightKg = profile.weightKg
        self.bmi = profile.bmi
        self.bmiCategory = profile.bmiCategory
        self.bmr = profile.bmr
        self.dailyStepGoal = profile.dailyStepGoal
        self.dailyCalorieGoal = profile.dailyCalorieGoal
        self.sleepGoalHours = profile.sleepGoalHours
        self.weeklyWorkoutGoal = profile.weeklyWorkoutGoal
    }
}

struct NutritionSnapshot {
    let totalCalories: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let waterIntake: Int
    let recentMeals: [MealSnapshot]
    
    init(from manager: NutritionManager) {
        self.totalCalories = manager.totalCalories
        self.totalProtein = manager.totalProtein
        self.totalCarbs = manager.totalCarbs
        self.totalFat = manager.totalFat
        self.waterIntake = manager.waterIntake
        self.recentMeals = manager.todaysFoods.map { MealSnapshot(from: $0) }
    }
}

struct MealSnapshot {
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    
    init(from food: FoodItem) {
        self.name = food.name
        self.calories = food.calories
        self.protein = food.protein
        self.carbs = food.carbs
        self.fat = food.fat
    }
}

struct MindfulnessSnapshot {
    // Placeholder - will implement when mindfulness tracking is added
    let meditationMinutesToday: Int = 0
    let breathingExercisesCompleted: Int = 0
    let currentMood: String = "neutral"
    
    init() {}
}

struct TemporalContext {
    let timeOfDay: String
    let dayOfWeek: String
    let partOfDay: String
    
    init() {
        let now = Date()
        let calendar = Calendar.current
        
        // Time of day
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        self.timeOfDay = formatter.string(from: now)
        
        // Day of week
        formatter.dateFormat = "EEEE"
        self.dayOfWeek = formatter.string(from: now)
        
        // Part of day
        let hour = calendar.component(.hour, from: now)
        switch hour {
        case 5..<12:
            self.partOfDay = "Morning"
        case 12..<17:
            self.partOfDay = "Afternoon"
        case 17..<21:
            self.partOfDay = "Evening"
        default:
            self.partOfDay = "Night"
        }
    }
}

