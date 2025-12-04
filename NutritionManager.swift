import Foundation
import Combine
import UIKit
import SwiftUI

struct FoodItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: String
    var timestamp: Date
    var imageData: Data?
    
    init(id: UUID = UUID(), name: String, calories: Int, protein: Double, carbs: Double, fat: Double, servingSize: String, timestamp: Date = Date(), imageData: Data? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.timestamp = timestamp
        self.imageData = imageData
    }
}

class NutritionManager: ObservableObject {
    @Published var todaysFoods: [FoodItem] = []
    @Published var waterIntake: Int = 0 // in ml
    
    var totalCalories: Int {
        todaysFoods.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        todaysFoods.reduce(0) { $0 + $1.protein }
    }
    
    var totalCarbs: Double {
        todaysFoods.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFat: Double {
        todaysFoods.reduce(0) { $0 + $1.fat }
    }
    
    init() {
        loadTodaysData()
    }
    
    func addFood(_ food: FoodItem) {
        todaysFoods.append(food)
        saveTodaysData()
    }
    
    func deleteFood(at offsets: IndexSet) {
        todaysFoods.remove(atOffsets: offsets)
        saveTodaysData()
    }
    
    // MARK: - Remove food by item (needed by NutritionView)
    func removeFood(_ food: FoodItem) {
        todaysFoods.removeAll { $0.id == food.id }
        saveTodaysData()
    }
    
    func addWater(ml: Int) {
        waterIntake += ml
        saveTodaysData()
    }
    
    func saveTodaysData() {
        if let encoded = try? JSONEncoder().encode(todaysFoods) {
            UserDefaults.standard.set(encoded, forKey: "todaysFoods")
        }
        UserDefaults.standard.set(waterIntake, forKey: "waterIntake")
        UserDefaults.standard.set(Date(), forKey: "lastSaveDate")
    }
    
    func loadTodaysData() {
        // Check if it's a new day
        if let lastDate = UserDefaults.standard.object(forKey: "lastSaveDate") as? Date {
            if !Calendar.current.isDateInToday(lastDate) {
                // New day - reset
                todaysFoods = []
                waterIntake = 0
                return
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: "todaysFoods"),
           let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) {
            todaysFoods = decoded
        }
        
        waterIntake = UserDefaults.standard.integer(forKey: "waterIntake")
    }
    
    // AI Food Recognition (placeholder - will integrate Vision + CoreML)
    func recognizeFood(from image: UIImage) -> FoodItem {
        // TODO: Integrate on-device food recognition model
        // For now, return a sample
        return FoodItem(
            name: "Detected Food",
            calories: 300,
            protein: 15,
            carbs: 40,
            fat: 10,
            servingSize: "1 serving"
        )
    }
}

