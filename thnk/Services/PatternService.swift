import Foundation
import CoreData

@MainActor
class PatternService: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    @Published var currentPatterns: PatternAnalysis?
    @Published var hasSignificantPatterns = false
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func analyzePatterns() async {
        // Get entries for different time ranges
        let todayEntries = await fetchTodaysEntries()
        let weekEntries = await fetchEntriesInLastWeek()
        let monthEntries = await fetchEntriesInLastMonth()
        
        // Analyze patterns for each time range
        let dailyPatterns = analyzeEmotionPatterns(from: todayEntries, timeRange: .today)
        let weeklyPatterns = analyzeEmotionPatterns(from: weekEntries, timeRange: .thisWeek)
        let monthlyPatterns = analyzeEmotionPatterns(from: monthEntries, timeRange: .thisMonth)
        
        // Create trajectory analysis
        let trajectory = createEmotionalTrajectory(from: todayEntries)
        
        let analysis = PatternAnalysis(
            dailyPatterns: dailyPatterns,
            weeklyPatterns: weeklyPatterns,
            monthlyPatterns: monthlyPatterns,
            trajectory: trajectory
        )
        
        currentPatterns = analysis
        hasSignificantPatterns = analysis.hasSignificantPatterns
    }
    
    private func fetchTodaysEntries() async -> [EmotionalEntry] {
        return await viewContext.perform {
            let request = EmotionalEntry.fetchTodaysEntries()
            return (try? self.viewContext.fetch(request)) ?? []
        }
    }
    
    private func fetchEntriesInLastWeek() async -> [EmotionalEntry] {
        return await viewContext.perform {
            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
            let request = EmotionalEntry.fetchEntriesInDateRange(from: weekAgo, to: Date())
            return (try? self.viewContext.fetch(request)) ?? []
        }
    }
    
    private func fetchEntriesInLastMonth() async -> [EmotionalEntry] {
        return await viewContext.perform {
            let calendar = Calendar.current
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
            let request = EmotionalEntry.fetchEntriesInDateRange(from: monthAgo, to: Date())
            return (try? self.viewContext.fetch(request)) ?? []
        }
    }
    
    private func analyzeEmotionPatterns(from entries: [EmotionalEntry], timeRange: EmotionPattern.TimeRange) -> [EmotionPattern] {
        guard entries.count >= 2 else { return [] }
        
        // Group entries by emotion
        let emotionGroups = Dictionary(grouping: entries) { entry in
            entry.primaryEmotion ?? "unknown"
        }
        
        var patterns: [EmotionPattern] = []
        
        for (emotion, emotionEntries) in emotionGroups {
            guard emotionEntries.count >= 2 else { continue }
            
            let frequency = emotionEntries.count
            let insights = EmotionPattern.generateInsights(
                for: emotion,
                frequency: frequency,
                timeRange: timeRange,
                entries: emotionEntries
            )
            
            let triggers = identifyTriggers(from: emotionEntries)
            
            let pattern = EmotionPattern(
                emotion: emotion,
                frequency: frequency,
                timeRange: timeRange,
                insights: insights,
                triggers: triggers
            )
            
            patterns.append(pattern)
        }
        
        // Sort by frequency (most frequent first)
        return patterns.sorted { $0.frequency > $1.frequency }
    }
    
    private func identifyTriggers(from entries: [EmotionalEntry]) -> [String] {
        // Simple trigger identification based on analysis text
        var triggers: [String] = []
        
        for entry in entries {
            guard let analysis = entry.analysis?.lowercased() else { continue }
            
            // Look for common trigger words/phrases
            if analysis.contains("work") || analysis.contains("deadline") || analysis.contains("meeting") {
                triggers.append("work-related")
            }
            if analysis.contains("relationship") || analysis.contains("friend") || analysis.contains("family") {
                triggers.append("relationships")
            }
            if analysis.contains("money") || analysis.contains("financial") || analysis.contains("budget") {
                triggers.append("financial")
            }
            if analysis.contains("health") || analysis.contains("tired") || analysis.contains("sleep") {
                triggers.append("health/energy")
            }
        }
        
        // Remove duplicates and return most common
        let uniqueTriggers = Array(Set(triggers))
        return Array(uniqueTriggers.prefix(3))
    }
    
    private func createEmotionalTrajectory(from entries: [EmotionalEntry]) -> EmotionalTrajectory? {
        guard entries.count >= 3 else { return nil }
        
        let sortedEntries = entries.sorted { entry1, entry2 in
            (entry1.timestamp ?? Date.distantPast) < (entry2.timestamp ?? Date.distantPast)
        }
        
        // Find emotion changes
        var emotionChanges: [EmotionalTrajectory.EmotionChange] = []
        
        for i in 1..<sortedEntries.count {
            let previousEntry = sortedEntries[i-1]
            let currentEntry = sortedEntries[i]
            
            guard let prevEmotion = previousEntry.primaryEmotion,
                  let currEmotion = currentEntry.primaryEmotion,
                  let prevTime = previousEntry.timestamp,
                  let currTime = currentEntry.timestamp,
                  prevEmotion != currEmotion else { continue }
            
            let timeBetween = currTime.timeIntervalSince(prevTime)
            
            let change = EmotionalTrajectory.EmotionChange(
                fromEmotion: prevEmotion,
                toEmotion: currEmotion,
                timeBetween: timeBetween,
                possibleTrigger: nil // Could enhance this later
            )
            
            emotionChanges.append(change)
        }
        
        // Determine dominant emotion
        let emotionCounts = Dictionary(grouping: sortedEntries) { entry in
            entry.primaryEmotion ?? "unknown"
        }.mapValues { $0.count }
        
        let dominantEmotion = emotionCounts.max { $0.value < $1.value }?.key ?? "mixed"
        
        // Generate insights
        let insights = generateTrajectoryInsights(from: emotionChanges, dominantEmotion: dominantEmotion)
        
        return EmotionalTrajectory(
            date: Date(),
            entries: sortedEntries,
            dominantEmotion: dominantEmotion,
            emotionChanges: emotionChanges,
            insights: insights
        )
    }
    
    private func generateTrajectoryInsights(from changes: [EmotionalTrajectory.EmotionChange], dominantEmotion: String) -> [String] {
        var insights: [String] = []
        
        if changes.isEmpty {
            insights.append("Your emotional state has been consistent today")
        } else if changes.count >= 3 {
            insights.append("You've experienced several emotional shifts today")
        }
        
        // Look for improvement patterns
        let positiveEmotions = ["joy", "happy", "content", "calm", "peaceful", "excited", "grateful"]
        let negativeEmotions = ["sad", "angry", "anxious", "frustrated", "stressed", "worried"]
        
        let endingPositively = changes.last.map { change in
            positiveEmotions.contains(change.toEmotion.lowercased())
        } ?? false
        
        if endingPositively {
            insights.append("It looks like things have shifted in a positive direction")
        }
        
        // Quick recovery patterns
        let quickRecoveries = changes.filter { change in
            negativeEmotions.contains(change.fromEmotion.lowercased()) &&
            positiveEmotions.contains(change.toEmotion.lowercased()) &&
            change.timeBetween < 3600 // Less than an hour
        }
        
        if !quickRecoveries.isEmpty {
            insights.append("You showed good emotional resilience today")
        }
        
        return insights
    }
    
    func getRecentPatternContext(for emotion: String) async -> String? {
        let recentEntries = await viewContext.perform {
            let request = EmotionalEntry.fetchEntriesByEmotion(emotion)
            request.fetchLimit = 3
            return (try? self.viewContext.fetch(request)) ?? []
        }
        
        guard !recentEntries.isEmpty else { return nil }
        
        let timestamps = recentEntries.compactMap { $0.timestamp }
        guard let mostRecent = timestamps.max() else { return nil }
        
        let timeAgo = timeAgoString(from: mostRecent)
        return "You last felt \(emotion) \(timeAgo)"
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minutes ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hours ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) days ago"
        }
    }
}