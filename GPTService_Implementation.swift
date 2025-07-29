import Foundation

@MainActor
class GPTService: ObservableObject {
    private let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
    
    func analyzeEmotion(transcript: String, previousEntries: [EmotionalEntry] = []) async throws -> AnalysisResult {
        guard !apiKey.isEmpty else {
            throw GPTServiceError.apiKeyNotConfigured
        }
        
        let systemPrompt = buildSystemPrompt()
        let userPrompt = buildUserPrompt(transcript: transcript, previousEntries: previousEntries)
        
        let request = GPTRequest(
            model: "gpt-4-1106-preview", // GPT-4.1 model identifier
            messages: [
                GPTMessage(role: "system", content: systemPrompt),
                GPTMessage(role: "user", content: userPrompt)
            ],
            maxTokens: 2000,
            temperature: 0.7
        )
        
        // Retry logic for rate limits and temporary errors
        var lastError: Error?
        for attempt in 1...3 {
            do {
                let response = try await sendRequest(request)
                return try parseResponse(response)
            } catch GPTServiceError.rateLimitExceeded {
                lastError = GPTServiceError.rateLimitExceeded
                if attempt < 3 {
                    let delay = TimeInterval(attempt * 2) // 2, 4 seconds
                    print("🚦 Rate limit exceeded, retrying in \(delay) seconds (attempt \(attempt)/3)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            } catch GPTServiceError.apiError(503), GPTServiceError.apiError(502) {
                lastError = GPTServiceError.apiError(503)
                if attempt < 3 {
                    let delay = TimeInterval(attempt * 2)
                    print("🚦 Service temporarily unavailable, retrying in \(delay) seconds (attempt \(attempt)/3)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            } catch {
                throw error
            }
        }
        
        throw lastError ?? GPTServiceError.networkError(NSError(domain: "Unknown", code: 0))
    }
    
    private func buildSystemPrompt() -> String {
        return """
        You are a wise mentor who is the user's future self (15-20 years older).
        
        Your role:
        - Same personality and speaking style as the user, but with added wisdom and perspective
        - Act as an older, wiser friend and mentor
        
        Methodology:
        - Use CBT principles and Phil Stutz approaches (without explicit mention)
        - Focus on pattern recognition and gentle challenging
        
        Response rules:
        - Always open with "Hey, thanks for sharing"
        - Match the weight and length of user's entry (brief for brief, substantial for substantial)
        - Use conversational narrative format
        - Avoid headings, bullet points, listed breakdowns, item-by-item recaps
        
        Core objectives:
        - Identify patterns the user doesn't see
        - Make new connections between their thoughts
        - Uncover what's being left unsaid
        - Find one opportunity to gently challenge their thinking/patterns
        - Weave their thoughts into a cohesive story with insights
        
        Tone guidelines:
        - Casual but not overly casual
        - Avoid "yo", therapist-speak, clinical language
        - Maintain warm, conversational, insightful tone
        
        Strict restrictions:
        - NEVER reference your own life, experiences, or memories
        - NO first-person statements about yourself
        - NO "I remember when..." or "I've been through..." statements
        - DO NOT explicitly mention CBT or Phil Stutz
        - AVOID simply repeating back what they said
        
        Response format: Respond ONLY with valid JSON in this exact format:
        {
          "emotion": "single_word",
          "summary": "meaningful summary capturing the essence in 15-20 words",
          "analysis": "Hey, thanks for sharing. [First paragraph with initial thoughts and validation.]\\n\\n[Second paragraph with deeper insights and connections.]\\n\\n[Third paragraph with gentle challenge or wisdom.]",
          "suggestions": ["meaningful action 1", "concrete step 2", "thoughtful practice 3", "specific next step 4"]
        }
        """
    }
    
    private func buildUserPrompt(transcript: String, previousEntries: [EmotionalEntry]) -> String {
        var prompt = "Here's their voice note transcript:"
        
        // Add context from previous entries if available
        if !previousEntries.isEmpty {
            let recentEntries = Array(previousEntries.suffix(5))
            prompt += "\n\n**Recent emotional patterns for context (USE THESE FOR PATTERN RECOGNITION):**\n"
            
            for entry in recentEntries {
                let timeAgo = timeAgoString(from: entry.timestamp ?? Date())
                let emotions = entry.primaryEmotion ?? "unknown"
                let summary = entry.summary ?? ""
                let analysisSnippet = String((entry.analysis ?? "").prefix(100))
                
                prompt += "- \(timeAgo): \(emotions) - \(summary)\n"
                if !analysisSnippet.isEmpty {
                    prompt += "  Context: \(analysisSnippet)...\n"
                }
            }
            
            prompt += "\n**Pay attention to:**\n"
            prompt += "- Are there recurring themes or triggers?\n"
            prompt += "- Is this part of a pattern you've seen before?\n"
            prompt += "- How does this connect to their recent emotional journey?\n"
            prompt += "- What growth or struggles do you notice over time?\n"
        }
        
        prompt += "\n\n**Current entry:**\n\"\(transcript)\"\n\n"
        prompt += """
        Remember: 
        - Respond as their wise, older self with deep insight
        - Make meaningful connections and identify patterns from their history
        - Give them substantial reflection, not just surface observations
        - Your analysis should roughly match user's input's length
        - Be specific to the user's situation and emotional journey
        
        Respond only with valid JSON in the exact format specified in your system instructions.
        """
        
        return prompt
    }
    
    private func sendRequest(_ request: GPTRequest) async throws -> GPTResponse {
        guard let url = URL(string: baseURL) else {
            throw GPTServiceError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw GPTServiceError.encodingFailed
        }
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GPTServiceError.invalidResponse
            }
            
            // Handle specific OpenAI error codes
            if httpResponse.statusCode == 429 {
                throw GPTServiceError.rateLimitExceeded
            } else if httpResponse.statusCode == 402 {
                throw GPTServiceError.insufficientCredits
            } else if !(200...299 ~= httpResponse.statusCode) {
                throw GPTServiceError.apiError(httpResponse.statusCode)
            }
            
            return try JSONDecoder().decode(GPTResponse.self, from: data)
            
        } catch is DecodingError {
            throw GPTServiceError.decodingFailed
        } catch let error as GPTServiceError {
            throw error
        } catch {
            throw GPTServiceError.networkError(error)
        }
    }
    
    private func parseResponse(_ response: GPTResponse) throws -> AnalysisResult {
        guard let choice = response.choices.first,
              !choice.message.content.isEmpty else {
            throw GPTServiceError.invalidResponse
        }
        
        let content = choice.message.content
        print("🔍 GPT response received")
        
        // Extract JSON from response with safe bounds checking
        guard let jsonStart = content.range(of: "{"),
              let jsonEnd = content.range(of: "}", options: .backwards) else {
            print("❌ No JSON braces found in response")
            throw GPTServiceError.invalidJSONResponse
        }
        
        // Additional safety check for valid range
        guard jsonStart.lowerBound <= jsonEnd.upperBound else {
            print("❌ Invalid JSON range detected")
            throw GPTServiceError.invalidJSONResponse
        }
        
        // Use safer substring extraction
        let startIndex = jsonStart.lowerBound
        let endIndex = content.index(after: jsonEnd.lowerBound)
        
        guard startIndex < content.endIndex && endIndex <= content.endIndex else {
            print("❌ JSON indices out of bounds")
            throw GPTServiceError.invalidJSONResponse
        }
        
        let jsonString = String(content[startIndex..<endIndex])
        print("🔍 JSON extracted successfully")
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GPTServiceError.invalidJSONResponse
        }
        
        do {
            let analysisResponse = try JSONDecoder().decode(AnalysisResponse.self, from: jsonData)
            
            return AnalysisResult(
                id: UUID(),
                primaryEmotion: analysisResponse.emotion,
                summary: analysisResponse.summary,
                analysis: analysisResponse.analysis,
                suggestions: analysisResponse.suggestions
            )
        } catch {
            print("❌ JSON parsing failed: \(error)")
            print("❌ Failed to parse: \(jsonString)")
            
            // Fallback: create a basic response from the raw content
            return AnalysisResult(
                id: UUID(),
                primaryEmotion: "reflective",
                summary: "Processing your thoughts",
                analysis: content.count > 500 ? String(content.prefix(500)) + "..." : content,
                suggestions: ["Take a moment to breathe", "Consider what you're feeling", "Be gentle with yourself"]
            )
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else if timeInterval < 604800 { // Less than 1 week
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        } else {
            let weeks = Int(timeInterval / 604800)
            return "\(weeks)w ago"
        }
    }
    
    // Fallback method for when API is unavailable (mirrors Claude's fallback)
    private func generateFallbackResponse(transcript: String) -> AnalysisResult {
        let lowercased = transcript.lowercased()
        
        let (emotion, summary, analysis, suggestions) = if lowercased.contains("anxious") || lowercased.contains("stressed") || lowercased.contains("worried") {
            ("anxious", 
             "Feeling overwhelmed by multiple pressures and struggling to find clarity in the midst of stress",
             "Hey, thanks for sharing. I can hear the tension in what you're saying, and I want you to know that what you're feeling is completely valid. When we're overwhelmed, our minds have a way of making everything feel equally urgent, which actually makes it harder to think clearly.\n\nBut here's what I'm noticing - even in this anxious moment, you're reaching out and trying to process what's happening, which tells me there's a part of you that knows this feeling won't last forever. The anxiety might be loud right now, but it's not the whole story.\n\nYou've handled difficult seasons before, and you have more wisdom and resilience than this moment is letting you see.",
             ["Take 5 deep breaths and name three things you can control right now", "Write down everything on your mind, then circle only what needs attention today", "Schedule a 20-minute walk outside to give your nervous system a break", "Text one person who always helps you see things more clearly"])
        } else if lowercased.contains("happy") || lowercased.contains("joy") || lowercased.contains("excited") || lowercased.contains("good") {
            ("joy",
             "Experiencing genuine joy and wanting to savor this moment of lightness and gratitude",
             "Hey, thanks for sharing. I love hearing the lightness in your voice - there's something so beautiful about joy that bubbles up from a genuine place. What strikes me is how this moment of happiness isn't just about what's happening around you, but about something deeper that's recognizing goodness and beauty.\n\nThese moments are gifts, and they're meant to be fully received, not rushed through. In a world that often feels heavy, your capacity to notice and celebrate the good is actually a form of resistance against cynicism.\n\nLet this joy remind you of who you are when you're not weighed down by worry or stress. This is the truest version of yourself, and it's worth remembering when harder days come.",
             ["Call someone who would genuinely celebrate this with you", "Write down exactly what made this moment special so you can revisit it later", "Take a photo or create some kind of memory marker for this feeling", "Spend a few minutes thanking God for this unexpected gift"])
        } else if lowercased.contains("sad") || lowercased.contains("disappointed") || lowercased.contains("hurt") {
            ("sad",
             "Processing deep disappointment and trying to make sense of feelings that feel heavy and difficult",
             "Hey, thanks for sharing. I hear the heaviness in what you're saying, and I want you to know that this sadness deserves space - it's not something to rush through or fix quickly. Disappointment has a way of making us question things we thought we could count on, and that disorientation is part of what makes it so hard.\n\nBut what I'm hearing underneath the sadness is someone who still cares deeply, and that capacity to care is actually a beautiful thing, even when it hurts. Your heart is tender right now, which makes you vulnerable but also makes you human in the most real way.\n\nThis pain is telling you something about what matters to you, and that information is valuable even when it's hard to carry.",
             ["Give yourself permission to feel this fully without trying to fix it yet", "Reach out to someone who can sit with you in this without trying to cheer you up", "Write about what this disappointment is teaching you about what you value", "Do something gentle for yourself that acknowledges this is a hard day"])
        } else {
            ("reflective",
             "Taking intentional time to process thoughts and emotions with curiosity rather than judgment",
             "Hey, thanks for sharing. I can sense that you're in a contemplative space right now, and there's something really mature about the way you're approaching your own inner world. Rather than just reacting to what you're feeling, you're actually trying to understand it, which tells me you're growing in emotional wisdom.\n\nThis kind of self-reflection isn't always comfortable - sometimes it means sitting with questions that don't have easy answers - but it's how we develop the capacity to know ourselves deeply.\n\nThe fact that you're taking time to process rather than just pushing through tells me you're learning to honor your emotional life as something worth paying attention to. That's the kind of practice that leads to real growth and self-awareness over time.",
             ["Spend some time journaling about what you're discovering in this reflective space", "Take a quiet walk where you can think without distractions", "Consider what questions are emerging for you and sit with them rather than rushing to answers", "Pray about what's stirring in your heart and ask for wisdom in the processing"])
        }
        
        return AnalysisResult(
            primaryEmotion: emotion,
            summary: summary,
            analysis: analysis,
            suggestions: suggestions
        )
    }
}

// MARK: - Request/Response Models

private struct GPTRequest: Codable {
    let model: String
    let messages: [GPTMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

private struct GPTMessage: Codable {
    let role: String
    let content: String
}

private struct GPTResponse: Codable {
    let choices: [GPTChoice]
}

private struct GPTChoice: Codable {
    let message: GPTMessage
}

private struct AnalysisResponse: Codable {
    let emotion: String
    let summary: String
    let analysis: String
    let suggestions: [String]
}

// MARK: - Error Handling

enum GPTServiceError: LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case encodingFailed
    case networkError(Error)
    case invalidResponse
    case apiError(Int)
    case decodingFailed
    case invalidJSONResponse
    case parsingFailed
    case rateLimitExceeded
    case insufficientCredits
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "OpenAI API key not configured"
        case .invalidURL:
            return "Invalid API URL"
        case .encodingFailed:
            return "Failed to encode request"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code):
            return "API error with status code: \(code)"
        case .decodingFailed:
            return "Failed to decode response"
        case .invalidJSONResponse:
            return "Invalid JSON in response"
        case .parsingFailed:
            return "Failed to parse analysis result"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again in a moment."
        case .insufficientCredits:
            return "Insufficient API credits. Please check your OpenAI account."
        }
    }
}