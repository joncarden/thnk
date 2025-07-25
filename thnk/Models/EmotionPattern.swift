import Foundation

struct EmotionPattern: Identifiable, Codable {
    let id: UUID
    let emotion: String
    let frequency: Int
    let timeRange: TimeRange
    let insights: [String]
    let triggers: [String]
    
    init(emotion: String, frequency: Int, timeRange: TimeRange, insights: [String], triggers: [String]) {
        self.id = UUID()
        self.emotion = emotion
        self.frequency = frequency
        self.timeRange = timeRange
        self.insights = insights
        self.triggers = triggers
    }
    
    enum TimeRange: String, CaseIterable, Codable {
        case today = "today"
        case thisWeek = "this_week"
        case thisMonth = "this_month"
        
        var displayName: String {
            switch self {
            case .today:
                return "Today"
            case .thisWeek:
                return "This Week"
            case .thisMonth:
                return "This Month"
            }
        }
    }
}

struct EmotionalTrajectory: Identifiable {
    let id: UUID
    let date: Date
    let entries: [EmotionalEntry]
    let dominantEmotion: String
    let emotionChanges: [EmotionChange]
    let insights: [String]
    
    init(date: Date, entries: [EmotionalEntry], dominantEmotion: String, emotionChanges: [EmotionChange], insights: [String]) {
        self.id = UUID()
        self.date = date
        self.entries = entries
        self.dominantEmotion = dominantEmotion
        self.emotionChanges = emotionChanges
        self.insights = insights
    }
    
    struct EmotionChange {
        let fromEmotion: String
        let toEmotion: String
        let timeBetween: TimeInterval
        let possibleTrigger: String?
    }
}

// MARK: - Pattern Analysis

struct PatternAnalysis {
    let dailyPatterns: [EmotionPattern]
    let weeklyPatterns: [EmotionPattern]
    let monthlyPatterns: [EmotionPattern]
    let trajectory: EmotionalTrajectory?
    
    var hasSignificantPatterns: Bool {
        return !dailyPatterns.isEmpty || !weeklyPatterns.isEmpty || !monthlyPatterns.isEmpty
    }
    
    var mostFrequentEmotion: String? {
        let allPatterns = dailyPatterns + weeklyPatterns + monthlyPatterns
        guard !allPatterns.isEmpty else { return nil }
        
        let emotionCounts = Dictionary(grouping: allPatterns, by: { $0.emotion })
            .mapValues { $0.reduce(0) { $0 + $1.frequency } }
        
        return emotionCounts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Pattern Insights

extension EmotionPattern {
    static func generateInsights(for emotion: String, frequency: Int, timeRange: TimeRange, entries: [EmotionalEntry]) -> [String] {
        var insights: [String] = []
        
        // Frequency-based insights
        if frequency >= 3 && timeRange == .today {
            insights.append("You've been feeling \(emotion) frequently today")
        }
        
        // Time-based patterns
        let timeBasedInsight = analyzeTimePatterns(entries: entries, emotion: emotion)
        if let insight = timeBasedInsight {
            insights.append(insight)
        }
        
        // Duration patterns
        let durationInsight = analyzeDurationPatterns(entries: entries, emotion: emotion)
        if let insight = durationInsight {
            insights.append(insight)
        }
        
        return insights
    }
    
    private static func analyzeTimePatterns(entries: [EmotionalEntry], emotion: String) -> String? {
        let emotionEntries = entries.filter { $0.primaryEmotion == emotion }
        guard emotionEntries.count >= 2 else { return nil }
        
        let calendar = Calendar.current
        let hours = emotionEntries.compactMap { entry -> Int? in
            guard let timestamp = entry.timestamp else { return nil }
            return calendar.component(.hour, from: timestamp)
        }
        
        // Find most common time period
        let timeGroups = Dictionary(grouping: hours) { hour in
            switch hour {
            case 6..<12: return "morning"
            case 12..<17: return "afternoon"
            case 17..<22: return "evening"
            default: return "night"
            }
        }
        
        if let mostCommonTime = timeGroups.max(by: { $0.value.count < $1.value.count }),
           mostCommonTime.value.count >= 2 {
            return "You tend to feel \(emotion) in the \(mostCommonTime.key)"
        }
        
        return nil
    }
    
    private static func analyzeDurationPatterns(entries: [EmotionalEntry], emotion: String) -> String? {
        // This could analyze how long emotional states last
        // For now, return a simple pattern
        if entries.count >= 3 {
            return "This emotion has been recurring over time"
        }
        return nil
    }
}