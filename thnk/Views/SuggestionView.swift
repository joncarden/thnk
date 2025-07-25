import SwiftUI

struct SuggestionView: View {
    let suggestion: String
    let index: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Suggestion counter
            if total > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<total, id: \.self) { dotIndex in
                        Circle()
                            .fill(dotIndex == index - 1 ? Color.primary.opacity(0.6) : Color.primary.opacity(0.2))
                            .frame(width: 5, height: 5)
                    }
                }
                .transition(.opacity)
            }
            
            // Suggestion text
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: suggestionIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.accentColor)
                    .padding(.top, 2)
                    .frame(minWidth: 20)
                
                Text(suggestion)
                    .font(.callout)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .animation(.easeInOut(duration: 0.3), value: suggestion)
    }
    
    private var suggestionIcon: String {
        let lowercased = suggestion.lowercased()
        
        if lowercased.contains("breath") || lowercased.contains("inhale") || lowercased.contains("exhale") {
            return "wind"
        } else if lowercased.contains("text") || lowercased.contains("call") || lowercased.contains("friend") {
            return "message"
        } else if lowercased.contains("walk") || lowercased.contains("move") || lowercased.contains("exercise") {
            return "figure.walk"
        } else if lowercased.contains("write") || lowercased.contains("journal") || lowercased.contains("list") {
            return "pencil"
        } else if lowercased.contains("break") || lowercased.contains("pause") || lowercased.contains("rest") {
            return "pause.circle"
        } else if lowercased.contains("water") || lowercased.contains("drink") {
            return "drop"
        } else if lowercased.contains("schedule") || lowercased.contains("appointment") || lowercased.contains("plan") {
            return "calendar"
        } else {
            return "lightbulb"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SuggestionView(
            suggestion: "Take 5 deep breaths right now to activate your parasympathetic nervous system",
            index: 1,
            total: 3
        )
        
        SuggestionView(
            suggestion: "Text a close friend to check in and share what's on your mind",
            index: 2,
            total: 3
        )
        
        SuggestionView(
            suggestion: "Schedule that doctor's appointment you've been putting off for weeks",
            index: 3,
            total: 3
        )
        
        SuggestionView(
            suggestion: "Take a 10-minute walk outside to get some fresh air and clear your head before continuing with your work",
            index: 1,
            total: 1
        )
    }
    .padding()
}