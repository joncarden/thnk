# Migration Plan: Claude to GPT-4.1

## Overview
This document outlines the complete migration strategy for replacing Claude AI with GPT-4.1 in the Thnk iOS app. The migration will maintain all existing functionality while adapting to OpenAI's API structure and capabilities.

## Current State Analysis

### Claude Service Implementation
- **File**: `ClaudeService.swift` (370 lines)
- **API Endpoint**: `https://api.anthropic.com/v1/messages`
- **Model**: `claude-3-5-sonnet-20241022`
- **Key Features**:
  - Emotional analysis with pattern recognition
  - Retry logic for 529 errors
  - Context from previous entries
  - JSON response parsing
  - Comprehensive error handling

### Integration Points
1. **ContentView.swift**: Main service instantiation and usage
2. **AnalysisResult.swift**: Unchanged data model
3. **Error handling**: Custom error types and user feedback

## Migration Strategy

### Phase 1: Preparation (1-2 days)

#### 1.1 Environment Setup
- [ ] Create OpenAI API account and obtain API key
- [ ] Update environment variables:
  ```bash
  # Replace CLAUDE_API_KEY with
  OPENAI_API_KEY=your_openai_api_key_here
  ```
- [ ] Research GPT-4.1 API documentation and limits

#### 1.2 API Comparison Analysis
| Feature | Claude | GPT-4.1 |
|---------|--------|---------|
| Endpoint | `/v1/messages` | `/v1/chat/completions` |
| Request Format | `messages` array | `messages` array (similar) |
| Max Tokens | 2000 | 4096 (higher limit) |
| Model Name | `claude-3-5-sonnet-20241022` | `gpt-4.1` |
| Headers | `x-api-key`, `anthropic-version` | `Authorization: Bearer` |

### Phase 2: Implementation (3-4 days)

#### 2.1 Create GPTService.swift
```swift
// New service class structure
@MainActor
class GPTService: ObservableObject {
    private let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    func analyzeEmotion(transcript: String, previousEntries: [EmotionalEntry] = []) async throws -> AnalysisResult
}
```

#### 2.2 API Request Structure Changes
```swift
// New request model
private struct GPTRequest: Codable {
    let model: String = "gpt-4.1"
    let messages: [GPTMessage]
    let maxTokens: Int
    let temperature: Double = 0.7
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

private struct GPTMessage: Codable {
    let role: String  // "system", "user", "assistant"
    let content: String
}
```

#### 2.3 Response Structure Adaptation
```swift
// New response model
private struct GPTResponse: Codable {
    let choices: [GPTChoice]
}

private struct GPTChoice: Codable {
    let message: GPTMessage
}
```

#### 2.4 Prompt Engineering Migration
- **Current**: Single user message with embedded instructions
- **New**: System message + user message pattern
- **Benefits**: Better instruction following, cleaner separation

```swift
// New prompt structure
let systemPrompt = """
You are a wise mentor who is the user's future self (15-20 years older)...
[Detailed system instructions]
"""

let userPrompt = """
Here's their voice note transcript:
"\(transcript)"
[Context and formatting instructions]
"""
```

### Phase 3: Testing & Validation (2-3 days)

#### 3.1 Unit Testing Strategy
- [ ] Create `GPTServiceTests.swift`
- [ ] Test API request/response parsing
- [ ] Validate error handling scenarios
- [ ] Compare output quality with Claude responses

#### 3.2 Integration Testing
- [ ] End-to-end workflow testing
- [ ] UI integration validation
- [ ] Error state handling
- [ ] Performance comparison

#### 3.3 Quality Assurance Checklist
- [ ] Response format consistency
- [ ] Emotional analysis accuracy
- [ ] Pattern recognition functionality
- [ ] Suggestion quality and relevance
- [ ] Error messages and user feedback

### Phase 4: Deployment (1 day)

#### 4.1 Code Replacement
- [ ] Replace `ClaudeService` with `GPTService` in `ContentView.swift`
- [ ] Update error handling references
- [ ] Remove Claude-specific dependencies

#### 4.2 Configuration Updates
- [ ] Update environment variable references
- [ ] Update API key validation logic
- [ ] Update error messages and logs

## Technical Implementation Details

### 3.1 Service Class Migration

#### Current (Claude):
```swift
class ClaudeService: ObservableObject {
    private let apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
    private let baseURL = "https://api.anthropic.com/v1/messages"
}
```

#### New (GPT):
```swift
class GPTService: ObservableObject {
    private let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    private let baseURL = "https://api.openai.com/v1/chat/completions"
}
```

### 3.2 Request Headers Migration

#### Current:
```swift
urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
```

#### New:
```swift
urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
```

### 3.3 Error Handling Migration

#### New Error Enum:
```swift
enum GPTServiceError: LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case encodingFailed
    case networkError(Error)
    case invalidResponse
    case apiError(Int)
    case decodingFailed
    case invalidJSONResponse
    case rateLimitExceeded
    case insufficientCredits
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "OpenAI API key not configured"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again in a moment."
        case .insufficientCredits:
            return "Insufficient API credits. Please check your OpenAI account."
        // ... other cases
        }
    }
}
```

### 3.4 Prompt Engineering Optimization

#### System Prompt:
```swift
private func buildSystemPrompt() -> String {
    return """
    You are a wise mentor who is the user's future self (15-20 years older).
    
    Your role:
    - Same personality and speaking style as the user, but with added wisdom
    - Act as an older, wiser friend and mentor
    
    Methodology:
    - Use CBT principles and Phil Stutz approaches (without explicit mention)
    - Focus on pattern recognition and gentle challenging
    
    Response rules:
    - Always open with "Hey, thanks for sharing"
    - Match the weight and length of user's entry
    - Use conversational narrative format
    - Avoid headings, bullet points, listed breakdowns
    
    Core objectives:
    - Identify patterns the user doesn't see
    - Make new connections between their thoughts
    - Uncover what's being left unsaid
    - Find one opportunity to gently challenge their thinking
    - Weave their thoughts into a cohesive story with insights
    
    Strict restrictions:
    - NEVER reference your own life or experiences
    - NO first-person statements about yourself
    - DO NOT explicitly mention CBT or Phil Stutz
    - AVOID simply repeating back what they said
    
    Response format: JSON only
    {
      "emotion": "single_word",
      "summary": "meaningful summary in 15-20 words",
      "analysis": "thoughtful response with \\n for paragraphs",
      "suggestions": ["action 1", "action 2", "action 3", "action 4"]
    }
    """
}
```

## Risk Assessment & Mitigation

### High Risk Items
1. **API Response Quality Changes**
   - **Risk**: GPT-4.1 responses may differ in tone/quality
   - **Mitigation**: Extensive prompt testing and refinement

2. **Rate Limiting Differences**
   - **Risk**: Different rate limits between providers
   - **Mitigation**: Implement robust retry logic with exponential backoff

3. **Cost Implications**
   - **Risk**: Token costs may differ significantly
   - **Mitigation**: Monitor usage and optimize prompt length

### Medium Risk Items
1. **JSON Parsing Reliability**
   - **Risk**: Different formatting consistency
   - **Mitigation**: Enhanced parsing with fallback mechanisms

2. **Context Window Management**
   - **Risk**: Different context length limits
   - **Mitigation**: Dynamic context truncation logic

## Testing Scenarios

### Functional Tests
1. **Basic Emotional Analysis**
   - Input: Simple emotional transcript
   - Expected: Valid JSON with emotion, summary, analysis, suggestions

2. **Pattern Recognition**
   - Input: Multiple related entries
   - Expected: Recognition of emotional patterns

3. **Error Handling**
   - Test API key missing
   - Test network failures
   - Test malformed responses

4. **Performance Tests**
   - Response time comparison
   - Token usage optimization
   - Memory usage validation

## Rollback Plan

### Immediate Rollback (< 1 hour)
1. Revert `ContentView.swift` to use `ClaudeService`
2. Restore Claude API key environment variable
3. Validate functionality with existing service

### Data Integrity
- No data migration required (AnalysisResult model unchanged)
- Existing Core Data entries remain compatible
- User data preserved throughout migration

## Success Metrics

### Technical Metrics
- [ ] Zero data loss during migration
- [ ] Response time ≤ current Claude performance
- [ ] Error rate < 5% for valid requests
- [ ] 100% feature parity maintained

### Quality Metrics
- [ ] User satisfaction maintained
- [ ] Analysis quality equivalent or better
- [ ] Suggestion relevance maintained
- [ ] Pattern recognition accuracy preserved

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|-----------------|
| Preparation | 1-2 days | API setup, research, planning |
| Implementation | 3-4 days | GPTService.swift, integration |
| Testing | 2-3 days | Unit tests, integration tests, QA |
| Deployment | 1 day | Code replacement, configuration |
| **Total** | **7-10 days** | Complete migration |

## Post-Migration Tasks

### Monitoring (First 2 weeks)
- [ ] Monitor error rates and response times
- [ ] Track user feedback and app store reviews
- [ ] Analyze cost implications and usage patterns
- [ ] Performance optimization if needed

### Documentation Updates
- [ ] Update README.md with new API requirements
- [ ] Update environment setup instructions
- [ ] Document any prompt engineering changes
- [ ] Update error handling documentation

### Future Optimizations
- [ ] Fine-tune prompts based on real usage
- [ ] Implement caching for repeated requests
- [ ] Explore GPT-4.1 advanced features
- [ ] Consider function calling for structured responses