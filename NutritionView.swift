import SwiftUI
import PhotosUI

struct NutritionView: View {
    @EnvironmentObject var nutritionManager: NutritionManager
    @EnvironmentObject var userProfile: UserProfile
    
    // Lazy init - only create when photo scan is used
    @State private var foodRecognition: FoodRecognitionService?
    
    @State private var showAddFood = false
    @State private var showPhotoOptions = false
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var selectedUIImage: UIImage?
    @State private var recognizedFoods: [FoodItem] = []
    @State private var showRecognitionResults = false
    @State private var isAnalyzing = false
    
    // Calendar state
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    
    var calorieProgress: Double {
        Double(nutritionManager.totalCalories) / Double(userProfile.dailyCalorieGoal)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.12, blue: 0.17)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header with Date Selector
                        headerView
                        
                        // Date Navigation
                        dateNavigationBar
                        
                        // Calorie Progress Ring
                        CalorieProgressRing(
                            current: nutritionManager.totalCalories,
                            goal: userProfile.dailyCalorieGoal,
                            progress: calorieProgress
                        )
                        
                        // Macros Summary
                        MacrosSummaryCard(
                            protein: nutritionManager.totalProtein,
                            carbs: nutritionManager.totalCarbs,
                            fat: nutritionManager.totalFat
                        )
                        
                        // Water Intake
                        WaterIntakeCard(
                            currentIntake: nutritionManager.waterIntake,
                            onAddWater: { amount in
                                nutritionManager.addWater(ml: amount)
                            }
                        )
                        
                        // Add Food Buttons
                        addFoodButtons
                        
                        // Today's Meals
                        if !nutritionManager.todaysFoods.isEmpty {
                            mealsSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .confirmationDialog("Choose Photo Source", isPresented: $showPhotoOptions) {
            Button("Take Photo") {
                showCameraPicker = true
            }
            Button("Choose from Library") {
                showLibraryPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera, selectedImage: $selectedUIImage)
        }
        .sheet(isPresented: $showLibraryPicker) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedUIImage)
        }
        .sheet(isPresented: $showAddFood) {
            AddFoodSheet()
                .environmentObject(nutritionManager)
        }
        .sheet(isPresented: $showRecognitionResults) {
            FoodRecognitionResultsSheet(
                foods: recognizedFoods,
                onAdd: { food in
                    nutritionManager.addFood(food)
                    showRecognitionResults = false
                }
            )
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate)
        }
        .onChange(of: selectedUIImage) { _, newValue in
            guard let image = newValue else { return }
            analyzeFood(image: image)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Nutrition")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { showDatePicker = true }) {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
            }
        }
    }
    
    // MARK: - Date Navigation
    
    private var dateNavigationBar: some View {
        HStack(spacing: 12) {
            // Previous day
            Button(action: { changeDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Date display
            Button(action: { showDatePicker = true }) {
                VStack(spacing: 2) {
                    Text(dateDisplayText)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(fullDateText)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            
            // Next day
            Button(action: { changeDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isToday ? .white.opacity(0.3) : .white.opacity(0.7))
            }
            .disabled(isToday)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var dateDisplayText: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: selectedDate)
        }
    }
    
    private var fullDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            // Don't go past today
            if newDate <= Date() {
                selectedDate = newDate
            }
        }
    }
    
    // MARK: - Add Food Buttons
    
    private var addFoodButtons: some View {
        VStack(spacing: 12) {
            // AI Photo Scan Button
            Button(action: {
                initializeFoodRecognition()
                showPhotoOptions = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                    Text("Scan Food with AI")
                        .font(.system(size: 17, weight: .semibold))
                    
                    if isAnalyzing {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Manual Add Button
            Button(action: { showAddFood = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Manually")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Meals Section
    
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Food")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(nutritionManager.todaysFoods.count) items")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            ForEach(nutritionManager.todaysFoods) { food in
                FoodItemCard(food: food, onDelete: {
                    nutritionManager.removeFood(food)
                })
            }
        }
    }
    
    // MARK: - Food Recognition (Lazy)
    
    private func initializeFoodRecognition() {
        if foodRecognition == nil {
            foodRecognition = FoodRecognitionService()
        }
    }
    
    private func analyzeFood(image: UIImage) {
        guard let service = foodRecognition else { return }
        
        isAnalyzing = true
        
        Task {
            let result = await service.recognizeFood(from: image)
            await MainActor.run {
                isAnalyzing = false
                if result.success && !result.foodItems.isEmpty {
                    recognizedFoods = result.foodItems
                    showRecognitionResults = true
                }
            }
        }
    }
}

// MARK: - Calorie Progress Ring

struct CalorieProgressRing: View {
    let current: Int
    let goal: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 20)
                    .frame(width: 180, height: 180)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        LinearGradient(
                            colors: [.green, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)
                
                // Center text
                VStack(spacing: 4) {
                    Text("\(current)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("/ \(goal) cal")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Remaining calories
            let remaining = max(0, goal - current)
            Text("\(remaining) calories remaining")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Macros Summary Card

struct MacrosSummaryCard: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    
    var body: some View {
        HStack(spacing: 0) {
            MacroItem(label: "Protein", value: protein, color: .red, unit: "g")
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))
            
            MacroItem(label: "Carbs", value: carbs, color: .blue, unit: "g")
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))
            
            MacroItem(label: "Fat", value: fat, color: .yellow, unit: "g")
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct MacroItem: View {
    let label: String
    let value: Double
    let color: Color
    let unit: String
    
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text("\(Int(value))\(unit)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Water Intake Card

struct WaterIntakeCard: View {
    let currentIntake: Int
    let onAddWater: (Int) -> Void
    
    let goal = 2000
    
    var progress: Double {
        Double(currentIntake) / Double(goal)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                
                Text("Water Intake")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(currentIntake) / \(goal) ml")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 12)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 12)
            
            // Quick add buttons
            HStack(spacing: 12) {
                WaterButton(amount: 250, onTap: onAddWater)
                WaterButton(amount: 500, onTap: onAddWater)
                WaterButton(amount: 750, onTap: onAddWater)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct WaterButton: View {
    let amount: Int
    let onTap: (Int) -> Void
    
    var body: some View {
        Button(action: { onTap(amount) }) {
            Text("+\(amount)ml")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.15))
                )
        }
    }
}

// MARK: - Food Item Card

struct FoodItemCard: View {
    let food: FoodItem
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 14) {
            // Food icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            }
            
            // Food info
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(food.servingSize)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Calories
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(food.calories)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("cal")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Delete button
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.11, blue: 0.16)
                    .ignoresSafeArea()
                
                VStack {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.cyan)
                    .colorScheme(.dark)
                    .padding()
                    
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.cyan)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}

// MARK: - Food Recognition Results Sheet

struct FoodRecognitionResultsSheet: View {
    let foods: [FoodItem]
    let onAdd: (FoodItem) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.11, blue: 0.16)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("AI identified \(foods.count) food item\(foods.count == 1 ? "" : "s")")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 20)
                        
                        ForEach(foods) { food in
                            Button(action: { onAdd(food) }) {
                                FoodItemCard(food: food)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Recognized Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}

// MARK: - Add Food Sheet

struct AddFoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var nutritionManager: NutritionManager
    
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = "1 serving"
    
    var isValid: Bool {
        !foodName.isEmpty && !calories.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.11, blue: 0.16)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        InputField(title: "Food Name", text: $foodName, placeholder: "e.g., Grilled Chicken")
                        InputField(title: "Calories", text: $calories, placeholder: "e.g., 250", keyboardType: .numberPad)
                        InputField(title: "Serving Size", text: $servingSize, placeholder: "e.g., 1 cup")
                        
                        Text("Macros (optional)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            SmallInputField(title: "Protein", text: $protein, placeholder: "g")
                            SmallInputField(title: "Carbs", text: $carbs, placeholder: "g")
                            SmallInputField(title: "Fat", text: $fat, placeholder: "g")
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addFood()
                        dismiss()
                    }
                    .foregroundColor(isValid ? .cyan : .gray)
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func addFood() {
        let food = FoodItem(
            name: foodName,
            calories: Int(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            servingSize: servingSize
        )
        nutritionManager.addFood(food)
    }
}

struct InputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .keyboardType(keyboardType)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )
                .foregroundColor(.white)
        }
    }
}

struct SmallInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .keyboardType(.decimalPad)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                )
                .foregroundColor(.white)
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // Check if camera is available, fallback to library
        if sourceType == .camera && UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
