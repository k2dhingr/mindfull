import Foundation
import Combine

class UserProfile: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 25
    @Published var heightCm: Double = 170
    @Published var weightKg: Double = 70
    @Published var gender: String = "Other"
    
    // Goals
    @Published var dailyStepGoal: Int = 10000
    @Published var dailyCalorieGoal: Int = 2000
    @Published var sleepGoalHours: Double = 8.0
    @Published var weeklyWorkoutGoal: Int = 3
    
    // Track if profile is complete
    @Published var isProfileComplete: Bool = false
    
    // Calculated properties
    var bmi: Double {
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }
    
    var bmiCategory: String {
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal"
        case 25..<30:
            return "Overweight"
        default:
            return "Obese"
        }
    }
    
    var bmr: Double {
        // Mifflin-St Jeor Equation
        if gender == "Male" {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        } else if gender == "Female" {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        } else {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 78
        }
    }
    
    // Save/Load from UserDefaults
    init() {
        loadProfile()
    }
    
    func saveProfile() {
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(age, forKey: "userAge")
        UserDefaults.standard.set(heightCm, forKey: "userHeight")
        UserDefaults.standard.set(weightKg, forKey: "userWeight")
        UserDefaults.standard.set(gender, forKey: "userGender")
        UserDefaults.standard.set(dailyStepGoal, forKey: "stepGoal")
        UserDefaults.standard.set(dailyCalorieGoal, forKey: "calorieGoal")
        UserDefaults.standard.set(sleepGoalHours, forKey: "sleepGoal")
        UserDefaults.standard.set(weeklyWorkoutGoal, forKey: "workoutGoal")
        UserDefaults.standard.set(isProfileComplete, forKey: "profileComplete")
    }
    
    func loadProfile() {
        name = UserDefaults.standard.string(forKey: "userName") ?? ""
        age = UserDefaults.standard.integer(forKey: "userAge")
        if age == 0 { age = 25 }
        heightCm = UserDefaults.standard.double(forKey: "userHeight")
        if heightCm == 0 { heightCm = 170 }
        weightKg = UserDefaults.standard.double(forKey: "userWeight")
        if weightKg == 0 { weightKg = 70 }
        gender = UserDefaults.standard.string(forKey: "userGender") ?? "Other"
        
        dailyStepGoal = UserDefaults.standard.integer(forKey: "stepGoal")
        if dailyStepGoal == 0 { dailyStepGoal = 10000 }
        dailyCalorieGoal = UserDefaults.standard.integer(forKey: "calorieGoal")
        if dailyCalorieGoal == 0 { dailyCalorieGoal = 2000 }
        sleepGoalHours = UserDefaults.standard.double(forKey: "sleepGoal")
        if sleepGoalHours == 0 { sleepGoalHours = 8.0 }
        weeklyWorkoutGoal = UserDefaults.standard.integer(forKey: "workoutGoal")
        if weeklyWorkoutGoal == 0 { weeklyWorkoutGoal = 3 }
        
        isProfileComplete = UserDefaults.standard.bool(forKey: "profileComplete")
    }
}
