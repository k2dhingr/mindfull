import Foundation
import UIKit
import Vision
import CoreML
import Combine

class FoodRecognitionService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var lastError: String?
    
    private var foodPrompt: String = ""
    
    init() {
        loadFoodPrompt()
    }
    
    private func loadFoodPrompt() {
        // ✅ FIXED: Use the new iOS 18 API with encoding parameter
        if let promptPath = Bundle.main.path(forResource: "food_nutrition_prompt", ofType: "txt"),
           let prompt = try? String(contentsOfFile: promptPath, encoding: .utf8) {
            foodPrompt = prompt
        }
    }
    
    // MARK: - Main Recognition Function
    
    func recognizeFood(from image: UIImage) async -> FoodRecognitionResult {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Step 1: Use Vision API to identify objects
        guard let identifiedFoods = await identifyFoodObjects(in: image) else {
            return FoodRecognitionResult(
                success: false,
                foodItems: [],
                error: "Could not identify food in image"
            )
        }
        
        // Step 2: Generate nutrition info for each identified food
        var foodItems: [FoodItem] = []
        
        for foodName in identifiedFoods {
            let nutrition = generateNutritionEstimate(for: foodName)
            foodItems.append(nutrition)
        }
        
        return FoodRecognitionResult(
            success: true,
            foodItems: foodItems,
            error: nil
        )
    }
    
    // MARK: - Vision API Integration
    
    private func identifyFoodObjects(in image: UIImage) async -> [String]? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            // Use Vision's built-in image classification
            let request = VNClassifyImageRequest { request, error in
                guard error == nil,
                      let results = request.results as? [VNClassificationObservation],
                      !results.isEmpty else {
                    // Fallback to generic food
                    continuation.resume(returning: ["food"])
                    return
                }
                
                // Filter for food-related classifications with confidence > 0.2
                let foodKeywords = ["food", "dish", "meal", "fruit", "vegetable", "meat",
                                    "bread", "rice", "pasta", "salad", "sandwich", "burger",
                                    "pizza", "chicken", "fish", "egg", "cheese", "milk",
                                    "coffee", "tea", "juice", "water", "soup", "dessert",
                                    "cake", "cookie", "chocolate", "apple", "banana", "orange",
                                    "plate", "bowl", "snack"]
                
                let identifiedFoods = results
                    .filter { observation in
                        observation.confidence > 0.2 &&
                        foodKeywords.contains(where: { observation.identifier.lowercased().contains($0) })
                    }
                    .prefix(3)
                    .map { $0.identifier.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? $0.identifier }
                
                if identifiedFoods.isEmpty {
                    // If no food found, return generic
                    continuation.resume(returning: ["food"])
                } else {
                    continuation.resume(returning: Array(identifiedFoods))
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("❌ Vision request failed: \(error)")
                continuation.resume(returning: ["food"])
            }
        }
    }
    
    // MARK: - Nutrition Estimation
    
    private func generateNutritionEstimate(for foodName: String) -> FoodItem {
        // Use comprehensive food database
        if let matchedFood = foodDatabase[foodName.lowercased()] {
            return matchedFood
        }
        
        // Try fuzzy matching
        for (key, food) in foodDatabase {
            if foodName.lowercased().contains(key) || key.contains(foodName.lowercased()) {
                return food
            }
        }
        
        // Generate intelligent estimate based on food type
        return generateIntelligentEstimate(for: foodName)
    }
    
    private func generateIntelligentEstimate(for foodName: String) -> FoodItem {
        let lower = foodName.lowercased()
        
        // Fruits
        if lower.contains("apple") || lower.contains("fruit") {
            return FoodItem(name: foodName, calories: 95, protein: 0.5, carbs: 25, fat: 0.3, servingSize: "1 medium")
        }
        
        // Proteins
        if lower.contains("chicken") || lower.contains("turkey") {
            return FoodItem(name: foodName, calories: 165, protein: 31, carbs: 0, fat: 3.6, servingSize: "100g")
        }
        
        if lower.contains("beef") || lower.contains("steak") {
            return FoodItem(name: foodName, calories: 250, protein: 26, carbs: 0, fat: 15, servingSize: "100g")
        }
        
        if lower.contains("fish") || lower.contains("salmon") {
            return FoodItem(name: foodName, calories: 206, protein: 22, carbs: 0, fat: 13, servingSize: "100g")
        }
        
        // Carbs
        if lower.contains("rice") {
            return FoodItem(name: foodName, calories: 205, protein: 4.3, carbs: 45, fat: 0.4, servingSize: "1 cup cooked")
        }
        
        if lower.contains("pasta") || lower.contains("noodle") {
            return FoodItem(name: foodName, calories: 220, protein: 8, carbs: 43, fat: 1.3, servingSize: "1 cup cooked")
        }
        
        if lower.contains("bread") {
            return FoodItem(name: foodName, calories: 80, protein: 4, carbs: 15, fat: 1, servingSize: "1 slice")
        }
        
        // Fast food
        if lower.contains("pizza") {
            return FoodItem(name: foodName, calories: 285, protein: 12, carbs: 36, fat: 10, servingSize: "1 slice")
        }
        
        if lower.contains("burger") {
            return FoodItem(name: foodName, calories: 354, protein: 20, carbs: 33, fat: 16, servingSize: "1 burger")
        }
        
        if lower.contains("sandwich") {
            return FoodItem(name: foodName, calories: 320, protein: 18, carbs: 38, fat: 10, servingSize: "1 sandwich")
        }
        
        // Vegetables
        if lower.contains("salad") || lower.contains("vegetable") {
            return FoodItem(name: foodName, calories: 150, protein: 5, carbs: 20, fat: 8, servingSize: "1 bowl")
        }
        
        // Dairy
        if lower.contains("milk") {
            return FoodItem(name: foodName, calories: 150, protein: 8, carbs: 12, fat: 8, servingSize: "1 cup")
        }
        
        if lower.contains("yogurt") {
            return FoodItem(name: foodName, calories: 100, protein: 17, carbs: 6, fat: 0.7, servingSize: "1 cup")
        }
        
        // Default estimate
        return FoodItem(name: foodName, calories: 200, protein: 10, carbs: 25, fat: 8, servingSize: "1 serving")
    }
    
    // MARK: - Food Database
    
    private var foodDatabase: [String: FoodItem] = [
        // Fruits
        "apple": FoodItem(name: "Apple", calories: 95, protein: 0.5, carbs: 25, fat: 0.3, servingSize: "1 medium"),
        "banana": FoodItem(name: "Banana", calories: 105, protein: 1.3, carbs: 27, fat: 0.4, servingSize: "1 medium"),
        "orange": FoodItem(name: "Orange", calories: 62, protein: 1.2, carbs: 15, fat: 0.2, servingSize: "1 medium"),
        
        // Proteins
        "chicken breast": FoodItem(name: "Chicken Breast", calories: 165, protein: 31, carbs: 0, fat: 3.6, servingSize: "100g cooked"),
        "salmon": FoodItem(name: "Salmon", calories: 206, protein: 22, carbs: 0, fat: 13, servingSize: "100g cooked"),
        "eggs": FoodItem(name: "Eggs", calories: 155, protein: 13, carbs: 1, fat: 11, servingSize: "2 large"),
        "tofu": FoodItem(name: "Tofu", calories: 144, protein: 17, carbs: 3, fat: 9, servingSize: "100g"),
        
        // Carbs
        "rice": FoodItem(name: "Rice", calories: 205, protein: 4.3, carbs: 45, fat: 0.4, servingSize: "1 cup cooked"),
        "pasta": FoodItem(name: "Pasta", calories: 220, protein: 8, carbs: 43, fat: 1.3, servingSize: "1 cup cooked"),
        "oatmeal": FoodItem(name: "Oatmeal", calories: 158, protein: 6, carbs: 28, fat: 3, servingSize: "1 cup cooked"),
        "sweet potato": FoodItem(name: "Sweet Potato", calories: 112, protein: 2, carbs: 26, fat: 0.1, servingSize: "1 medium baked"),
        
        // Vegetables
        "broccoli": FoodItem(name: "Broccoli", calories: 55, protein: 4, carbs: 11, fat: 0.6, servingSize: "1 cup cooked"),
        "spinach": FoodItem(name: "Spinach", calories: 41, protein: 5, carbs: 7, fat: 0.5, servingSize: "1 cup cooked"),
        "avocado": FoodItem(name: "Avocado", calories: 234, protein: 3, carbs: 12, fat: 21, servingSize: "1 medium"),
        
        // Dairy
        "greek yogurt": FoodItem(name: "Greek Yogurt", calories: 100, protein: 17, carbs: 6, fat: 0.7, servingSize: "1 cup"),
        "milk": FoodItem(name: "Milk", calories: 150, protein: 8, carbs: 12, fat: 8, servingSize: "1 cup"),
        "cheese": FoodItem(name: "Cheese", calories: 113, protein: 7, carbs: 1, fat: 9, servingSize: "1 oz"),
        
        // Fast food
        "pizza": FoodItem(name: "Pizza Slice", calories: 285, protein: 12, carbs: 36, fat: 10, servingSize: "1 slice"),
        "burger": FoodItem(name: "Burger", calories: 354, protein: 20, carbs: 33, fat: 16, servingSize: "1 burger"),
        "sandwich": FoodItem(name: "Sandwich", calories: 320, protein: 18, carbs: 38, fat: 10, servingSize: "1 sandwich"),
        
        // Snacks
        "almonds": FoodItem(name: "Almonds", calories: 164, protein: 6, carbs: 6, fat: 14, servingSize: "1 oz (23 nuts)"),
        "protein bar": FoodItem(name: "Protein Bar", calories: 200, protein: 20, carbs: 22, fat: 6, servingSize: "1 bar")
    ]
}

// MARK: - Supporting Types

struct FoodRecognitionResult {
    let success: Bool
    let foodItems: [FoodItem]
    let error: String?
}
