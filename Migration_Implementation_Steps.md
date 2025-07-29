# GPT-4.1 Migration: Implementation Steps

## Step-by-Step Implementation Guide

This document provides the exact steps and code changes needed to migrate from Claude to GPT-4.1.

## Pre-Migration Checklist

### 1. Environment Setup
- [ ] Obtain OpenAI API key from https://platform.openai.com/
- [ ] Set environment variable: `OPENAI_API_KEY=your_key_here`
- [ ] Verify current Claude integration is working
- [ ] Create backup of current codebase

### 2. Preparation
- [ ] Review `GPT_Migration_Plan.md` for complete strategy
- [ ] Ensure `GPTService_Implementation.swift` template is available
- [ ] Plan testing approach and test cases

## Implementation Steps

### Step 1: Add GPTService.swift to Project (15 minutes)

1. **Create new file**: `thnk/Services/GPTService.swift`
2. **Copy content** from `GPTService_Implementation.swift`
3. **Add to Xcode project**:
   - Right-click on `Services` folder in Xcode
   - Select "Add Files to 'thnk'"
   - Choose `GPTService.swift`
   - Ensure target is selected

### Step 2: Update ContentView.swift (10 minutes)

#### 2.1 Replace Service Import and Instantiation

**Current code (Line 8):**
```swift
@StateObject private var claudeService = ClaudeService()
```

**Replace with:**
```swift
@StateObject private var gptService = GPTService()
```

#### 2.2 Update Service Call

**Current code (Line 204):**
```swift
let result = try await claudeService.analyzeEmotion(transcript: transcript, previousEntries: previousEntries)
```

**Replace with:**
```swift
let result = try await gptService.analyzeEmotion(transcript: transcript, previousEntries: previousEntries)
```

#### 2.3 Update Error Handling

**Current code (Lines 236-250):**
```swift
if let claudeError = error as? ClaudeServiceError {
    switch claudeError {
    case .apiKeyNotConfigured:
        print("⚠️ Claude API key not configured. Set CLAUDE_API_KEY environment variable.")
    case .networkError(let networkError):
        print("🌐 Network error: \(networkError.localizedDescription)")
    case .apiError(let statusCode):
        if statusCode == 529 {
            print("🚦 Claude API is temporarily overloaded (529). Retrying in a moment...")
        } else {
            print("🚫 API error with status code: \(statusCode)")
        }
    default:
        print("🔍 Claude service error: \(claudeError.localizedDescription)")
    }
}
```

**Replace with:**
```swift
if let gptError = error as? GPTServiceError {
    switch gptError {
    case .apiKeyNotConfigured:
        print("⚠️ OpenAI API key not configured. Set OPENAI_API_KEY environment variable.")
    case .networkError(let networkError):
        print("🌐 Network error: \(networkError.localizedDescription)")
    case .rateLimitExceeded:
        print("🚦 OpenAI rate limit exceeded. Retrying in a moment...")
    case .insufficientCredits:
        print("💳 Insufficient OpenAI credits. Please check your account.")
    case .apiError(let statusCode):
        print("🚫 API error with status code: \(statusCode)")
    default:
        print("🔍 GPT service error: \(gptError.localizedDescription)")
    }
}
```

### Step 3: Remove ClaudeService.swift (5 minutes)

1. **In Xcode**: Right-click on `ClaudeService.swift`
2. **Select**: "Move to Trash"
3. **Confirm**: Remove references

**Alternative**: Keep file but rename to `ClaudeService.swift.backup` for rollback

### Step 4: Update Environment Variables (5 minutes)

#### 4.1 Development Environment
Update your development environment to use the new API key:

```bash
# Remove old variable
unset CLAUDE_API_KEY

# Add new variable
export OPENAI_API_KEY="your_openai_api_key_here"
```

#### 4.2 Production Environment
Update deployment scripts and environment configurations to use `OPENAI_API_KEY` instead of `CLAUDE_API_KEY`.

### Step 5: Build and Test (20 minutes)

#### 5.1 Build Verification
1. **Clean build folder**: Cmd+Shift+K in Xcode
2. **Build project**: Cmd+B
3. **Resolve any compilation errors**

#### 5.2 Basic Functionality Test
1. **Run app** on simulator/device
2. **Record voice note** with simple emotional content
3. **Verify analysis** is generated correctly
4. **Check suggestions** are relevant and properly formatted

#### 5.3 Error Handling Test
1. **Remove API key** temporarily
2. **Trigger API key error**
3. **Verify error message** shows OpenAI-specific text
4. **Restore API key**

## Detailed Code Changes

### ContentView.swift Changes

#### Change 1: Service Declaration
```swift
// OLD
@StateObject private var claudeService = ClaudeService()

// NEW  
@StateObject private var gptService = GPTService()
```

#### Change 2: Analysis Call
```swift
// OLD
let result = try await claudeService.analyzeEmotion(transcript: transcript, previousEntries: previousEntries)

// NEW
let result = try await gptService.analyzeEmotion(transcript: transcript, previousEntries: previousEntries)
```

#### Change 3: Error Type Check
```swift
// OLD
if let claudeError = error as? ClaudeServiceError {

// NEW
if let gptError = error as? GPTServiceError {
```

#### Change 4: API Key Error Message
```swift
// OLD
print("⚠️ Claude API key not configured. Set CLAUDE_API_KEY environment variable.")

// NEW
print("⚠️ OpenAI API key not configured. Set OPENAI_API_KEY environment variable.")
```

#### Change 5: Rate Limit Handling
```swift
// OLD
case .apiError(let statusCode):
    if statusCode == 529 {
        print("🚦 Claude API is temporarily overloaded (529). Retrying in a moment...")
    }

// NEW
case .rateLimitExceeded:
    print("🚦 OpenAI rate limit exceeded. Retrying in a moment...")
case .insufficientCredits:
    print("💳 Insufficient OpenAI credits. Please check your account.")
```

## Testing Checklist

### Functional Tests
- [ ] **Voice Recording**: App can record audio
- [ ] **Speech-to-Text**: Audio converts to text correctly
- [ ] **GPT Analysis**: Text generates emotional analysis
- [ ] **JSON Parsing**: Response format is correct
- [ ] **UI Display**: Analysis shows in AnalysisView
- [ ] **Core Data**: Entries save to database
- [ ] **Pattern Recognition**: Previous entries provide context

### Error Handling Tests
- [ ] **Missing API Key**: Shows appropriate error
- [ ] **Network Failure**: Handles connection errors gracefully
- [ ] **Rate Limiting**: Retry logic works correctly
- [ ] **Invalid Response**: Fallback response generated
- [ ] **JSON Parsing Failure**: Graceful degradation

### Quality Assurance
- [ ] **Response Quality**: Analysis is thoughtful and relevant
- [ ] **Suggestions**: Actions are concrete and helpful
- [ ] **Tone Consistency**: Maintains "wise mentor" voice
- [ ] **Pattern Recognition**: References previous entries appropriately

## Rollback Procedure

If issues arise during migration:

### Immediate Rollback (< 10 minutes)
1. **Restore ClaudeService.swift** to project
2. **Revert ContentView.swift** changes:
   ```swift
   // Restore these lines
   @StateObject private var claudeService = ClaudeService()
   let result = try await claudeService.analyzeEmotion(...)
   if let claudeError = error as? ClaudeServiceError {
   ```
3. **Remove GPTService.swift** from project
4. **Restore environment variable**: `CLAUDE_API_KEY`

### Validation After Rollback
- [ ] App builds successfully
- [ ] Claude service responds correctly
- [ ] No data loss occurred
- [ ] All functionality restored

## Post-Migration Verification

### Performance Metrics
- [ ] **Response Time**: Compare with Claude baseline
- [ ] **Error Rate**: Monitor for first 24 hours
- [ ] **Cost Analysis**: Track token usage and costs
- [ ] **User Experience**: No degradation in app usability

### Monitoring Setup
1. **Add logging** for GPT response times
2. **Track error rates** by error type
3. **Monitor API costs** through OpenAI dashboard
4. **Set up alerts** for unusual error patterns

## Additional Considerations

### Model Updates
- **Current model**: `gpt-4-1106-preview` (GPT-4.1)
- **Future updates**: Monitor OpenAI releases for newer models
- **Easy to update**: Change model name in `GPTService.swift`

### Cost Optimization
- **Token counting**: Consider implementing token usage tracking
- **Prompt optimization**: Monitor for unnecessary verbosity
- **Caching**: Consider caching for repeated similar requests

### Feature Enhancements
- **Function calling**: GPT-4.1 supports structured function calls
- **Enhanced context**: Higher token limits allow more history
- **Multi-modal**: Future support for image/audio analysis

## Success Criteria

Migration is considered successful when:
- [ ] All existing functionality works identically
- [ ] No data loss or corruption
- [ ] Error handling is appropriate for OpenAI
- [ ] Response quality meets or exceeds Claude
- [ ] Performance is comparable or better
- [ ] Cost is manageable and predictable

## Support Resources

### OpenAI Documentation
- **API Reference**: https://platform.openai.com/docs/api-reference
- **Rate Limits**: https://platform.openai.com/docs/guides/rate-limits
- **Error Codes**: https://platform.openai.com/docs/guides/error-codes

### Troubleshooting
- **API Key Issues**: Verify key format and permissions
- **Rate Limits**: Implement exponential backoff
- **JSON Parsing**: Enhance error handling and fallbacks
- **Cost Management**: Set usage limits in OpenAI dashboard