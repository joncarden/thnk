import Foundation

struct AnalysisResult: Identifiable, Codable {
    let id: UUID
    let primaryEmotion: String
    let summary: String
    let analysis: String
    let suggestions: [String]
    
    init(id: UUID = UUID(), primaryEmotion: String, summary: String, analysis: String, suggestions: [String]) {
        self.id = id
        self.primaryEmotion = primaryEmotion
        self.summary = summary
        self.analysis = analysis
        self.suggestions = suggestions
    }
    
    // Format for sharing to Notes or other apps
    var formattedForSharing: String {
        let timestamp = DateFormatter.dateTimeFormatter.string(from: Date())
        
        return """
        🧠 thnk Reflection - \(timestamp)
        
        Emotion: \(primaryEmotion.capitalized)
        Summary: \(summary)
        
        Analysis:
        \(analysis)
        
        Suggested Actions:
        \(suggestions.enumerated().map { "• \($0.element)" }.joined(separator: "\n"))
        
        ---
        Created with thnk
        """
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Sample Data for Previews

extension AnalysisResult {
    static let sample = AnalysisResult(
        primaryEmotion: "anxious",
        summary: "Feeling overwhelmed by work deadlines and competing priorities",
        analysis: "Hey, thanks for sharing. My thoughts: It sounds like you're in that familiar spot where everything feels urgent at once. I hear the stress in how you're describing these deadlines, but I also hear someone who cares deeply about doing good work. That's both your strength and what's wearing you down right now.",
        suggestions: [
            "Take 5 deep breaths right now",
            "Write down your top 3 priorities for today",
            "Schedule a 15-minute walk break"
        ]
    )
    
    static let joyful = AnalysisResult(
        primaryEmotion: "joy",
        summary: "Celebrating a recent achievement and feeling grateful",
        analysis: "Hey, thanks for sharing. My thoughts: I love hearing the genuine happiness in your voice! This moment of gratitude isn't just about the achievement itself - it's about recognizing how your hard work and perseverance paid off. Don't rush past this feeling; let it settle in and remind you what you're capable of.",
        suggestions: [
            "Call someone who supported you through this",
            "Write down what this achievement means to you",
            "Celebrate with something meaningful to you"
        ]
    )
    
    static let confused = AnalysisResult(
        primaryEmotion: "confused",
        summary: "Processing a difficult decision with uncertainty about next steps",
        analysis: "Hey, thanks for sharing. My thoughts: I hear you wrestling with this decision, and honestly, the fact that you're taking time to think it through shows wisdom. Sometimes confusion isn't a sign you're lost - it's a sign you're taking something seriously that deserves serious thought. The clarity will come.",
        suggestions: [
            "Write down your core values and see which option aligns",
            "Talk to someone whose judgment you trust",
            "Give yourself permission to sit with uncertainty for now"
        ]
    )
}
