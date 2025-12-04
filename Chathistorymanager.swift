import Foundation
import Combine

// MARK: - ChatMessage (Codable for persistence)
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
    
    // Convenience initializer with 'text' for backwards compatibility
    init(text: String, isUser: Bool) {
        self.id = UUID()
        self.content = text
        self.isUser = isUser
        self.timestamp = Date()
    }
}

class ChatHistoryManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    
    private let maxMessages = 1000  // Keep last 1000 messages
    private let contextWindow = 20   // Send last 20 to AI
    
    private let storageKey = "chat_history"
    private let lastClearKey = "last_history_clear"
    
    init() {
        loadHistory()
        checkAndClearOldHistory()
    }
    
    // MARK: - Public Methods
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        
        // Trim if exceeds max
        if messages.count > maxMessages {
            messages.removeFirst(messages.count - maxMessages)
        }
        
        saveHistory()
    }
    
    func addUserMessage(_ text: String) {
        let message = ChatMessage(content: text, isUser: true)
        addMessage(message)
    }
    
    func addAIMessage(_ text: String) {
        let message = ChatMessage(content: text, isUser: false)
        addMessage(message)
    }
    
    func getRecentMessages(count: Int = 20) -> [ChatMessage] {
        return Array(messages.suffix(count))
    }
    
    func getContextWindowMessages() -> [ChatMessage] {
        return Array(messages.suffix(contextWindow))
    }
    
    func clearHistory() {
        messages.removeAll()
        saveHistory()
        UserDefaults.standard.set(Date(), forKey: lastClearKey)
    }
    
    func getTodaysMessages() -> [ChatMessage] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return messages.filter { message in
            calendar.isDate(message.timestamp, inSameDayAs: today)
        }
    }
    
    func getMessageCount() -> Int {
        return messages.count
    }
    
    // MARK: - Persistence
    
    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(messages)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save chat history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            messages = try decoder.decode([ChatMessage].self, from: data)
            print("✅ Loaded \(messages.count) chat messages")
        } catch {
            print("❌ Failed to load chat history: \(error)")
        }
    }
    
    private func checkAndClearOldHistory() {
        // Clear history older than 30 days
        guard let lastClear = UserDefaults.standard.object(forKey: lastClearKey) as? Date else {
            UserDefaults.standard.set(Date(), forKey: lastClearKey)
            return
        }
        
        let daysSinceLastClear = Calendar.current.dateComponents([.day], from: lastClear, to: Date()).day ?? 0
        
        if daysSinceLastClear > 30 {
            // Remove messages older than 30 days
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            messages = messages.filter { $0.timestamp > thirtyDaysAgo }
            saveHistory()
            UserDefaults.standard.set(Date(), forKey: lastClearKey)
            print("🧹 Cleared chat history older than 30 days")
        }
    }
    
    // MARK: - Statistics
    
    func getStatistics() -> ChatStatistics {
        let totalMessages = messages.count
        let userMessages = messages.filter { $0.isUser }.count
        let aiMessages = messages.filter { !$0.isUser }.count
        
        let todaysMessages = getTodaysMessages()
        let todaysCount = todaysMessages.count
        
        let calendar = Calendar.current
        let last7Days = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekMessages = messages.filter { $0.timestamp > last7Days }.count
        
        return ChatStatistics(
            totalMessages: totalMessages,
            userMessages: userMessages,
            aiMessages: aiMessages,
            todaysMessages: todaysCount,
            weekMessages: weekMessages
        )
    }
}

// MARK: - Supporting Types

struct ChatStatistics {
    let totalMessages: Int
    let userMessages: Int
    let aiMessages: Int
    let todaysMessages: Int
    let weekMessages: Int
    
    var avgMessagesPerDay: Double {
        guard totalMessages > 0 else { return 0 }
        // Estimate based on week messages
        return Double(weekMessages) / 7.0
    }
}

// MARK: - ChatMessage Extension

extension ChatMessage {
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(timestamp)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(timestamp)
    }
    
    var relativeDate: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: timestamp)
        }
    }
}

