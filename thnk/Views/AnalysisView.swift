import SwiftUI

extension String {
    var paragraphs: [String] {
        return self.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

struct AnalysisView: View {
    let result: AnalysisResult
    
    @State private var currentSuggestionIndex = 0
    @State private var displayedText = ""
    @State private var showingSuggestions = false
    @State private var showingShareSheet = false
    
    private let typingDelay: Double = 0.03
    private let suggestionCycleDuration: Double = 5.0
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                // SECTION 1: Emotional State
                VStack(spacing: 16) {
                    EmotionIndicator(emotion: result.primaryEmotion)
                    
                    Text(result.summary)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 16)
                
                // SECTION 2: Response
                VStack(alignment: .leading, spacing: 16) {
                    // Section header
                    HStack {
                        Text("a few thoughts")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    // Analysis content with paragraph formatting
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(displayedText.paragraphs, id: \.self) { paragraph in
                            if !paragraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(paragraph)
                                    .font(.body)
                                    .lineSpacing(4)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                    
                    // Save button attached to response box
                    HStack {
                        Spacer()
                        Button(action: { showingShareSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .medium))
                                Text("save to notes")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                }
                
                // SECTION 3: Next Steps
                if showingSuggestions && !result.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        // Section header
                        HStack {
                            Text("possible next steps")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        // Suggestions content with swipe gesture
                        SuggestionView(
                            suggestion: result.suggestions[currentSuggestionIndex],
                            index: currentSuggestionIndex + 1,
                            total: result.suggestions.count
                        )
                        .padding(.horizontal, 16)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.width > 50 {
                                        // Swipe right - previous suggestion
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentSuggestionIndex = currentSuggestionIndex > 0 ? 
                                                currentSuggestionIndex - 1 : 
                                                result.suggestions.count - 1
                                        }
                                    } else if value.translation.width < -50 {
                                        // Swipe left - next suggestion
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentSuggestionIndex = (currentSuggestionIndex + 1) % result.suggestions.count
                                        }
                                    }
                                }
                        )
                    }
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Bottom padding for comfortable scrolling
                Color.clear.frame(height: 32)
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            startTypingAnimation()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [result.formattedForSharing])
        }
    }
    
    private func startTypingAnimation() {
        let fullText = result.analysis
        displayedText = ""
        
        // Safety check for empty text
        guard !fullText.isEmpty else {
            displayedText = fullText
            showingSuggestions = true
            return
        }
        
        Task {
            for index in 0..<fullText.count {
                await MainActor.run {
                    // Use safe string slicing to prevent index crashes
                    if index + 1 <= fullText.count {
                        let endIndex = fullText.index(fullText.startIndex, offsetBy: index + 1)
                        if endIndex <= fullText.endIndex {
                            displayedText = String(fullText[..<endIndex])
                        }
                    }
                }
                
                try? await Task.sleep(nanoseconds: UInt64(typingDelay * 1_000_000_000))
            }
            
            // Show suggestions after analysis is complete
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showingSuggestions = true
                }
            }
            
            // Start suggestion cycling
            if result.suggestions.count > 1 {
                startSuggestionCycling()
            }
        }
    }
    
    private func startSuggestionCycling() {
        Timer.scheduledTimer(withTimeInterval: suggestionCycleDuration, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSuggestionIndex = (currentSuggestionIndex + 1) % result.suggestions.count
            }
        }
    }
    
}

struct EmotionIndicator: View {
    let emotion: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(emotionColor)
                .frame(width: 12, height: 12)
            
            Text(emotion.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(emotionColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(emotionColor.opacity(0.1))
        )
    }
    
    private var emotionColor: Color {
        switch emotion.lowercased() {
        case "joy", "happy", "excited", "content":
            return .green
        case "sad", "disappointed", "melancholy":
            return .blue
        case "angry", "frustrated", "irritated":
            return .red
        case "anxious", "worried", "nervous", "stressed":
            return .orange
        case "calm", "peaceful", "relaxed":
            return .mint
        case "confused", "uncertain":
            return .purple
        default:
            return .gray
        }
    }
}

#Preview {
    AnalysisView(
        result: AnalysisResult(
            id: UUID(),
            primaryEmotion: "anxious",
            summary: "Feeling overwhelmed by work deadlines and struggling to find clarity in competing priorities",
            analysis: "Hey, thanks for sharing. I can hear the tension in what you're saying about these deadlines, and I want you to know that what you're feeling is completely valid. When we're overwhelmed, our minds have a way of making everything feel equally urgent, which actually makes it harder to think clearly about what really needs attention first. But here's what I'm noticing - even in this anxious moment, you're taking time to process what's happening rather than just pushing through, which tells me there's wisdom in how you're approaching this. The pressure is real, but so is your capacity to handle difficult seasons. You've navigated competing priorities before, and you have more clarity than this overwhelming moment is letting you see right now.",
            suggestions: [
                "Take 5 deep breaths and name three things you can control right now",
                "Write down everything on your mind, then circle only what needs attention today", 
                "Schedule a 20-minute walk outside to give your nervous system a break",
                "Text one person who always helps you see things more clearly"
            ]
        )
    )
    .padding()
}
