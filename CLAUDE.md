# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the thnk iOS project.

## Project Overview

thnk is a minimalist iOS emotional companion app that allows users to process feelings through voice in real-time. The app combines voice recording, on-device speech-to-text processing, and Claude AI-powered emotional analysis with a focus on privacy and simplicity.

## Core Architecture

### Technology Stack
- **Platform**: iOS 16.0+
- **Framework**: SwiftUI
- **Language**: Swift 5.9+
- **AI Integration**: Claude API (Anthropic) - claude-sonnet-4-20250514
- **Speech Processing**: iOS Speech Framework (on-device)
- **Data Storage**: Core Data with encryption
- **Audio**: AVAudioSession with AVAudioRecorder

### Project Structure
```
thnk/
├── App/                     # Main app entry points
│   ├── ThnkApp.swift      # App delegate and Core Data setup
│   └── ContentView.swift   # Main interface coordinator
├── Views/                   # SwiftUI view components
│   ├── RecordingView.swift # Voice recording interface
│   ├── AnalysisView.swift  # Emotional analysis display
│   └── SuggestionView.swift # Actionable suggestions
├── Services/               # Business logic services
│   ├── AudioManager.swift  # Audio recording & playback
│   ├── SpeechService.swift # Speech-to-text processing
│   ├── ClaudeService.swift # AI analysis integration
│   └── PatternService.swift # Emotional pattern recognition
├── Models/                 # Data models
│   ├── EmotionalEntry.swift # Core Data entity
│   ├── AnalysisResult.swift # AI response structure
│   └── EmotionPattern.swift # Pattern tracking models
└── Core Data/              # Data persistence
    └── ThnkDataModel.xcdatamodeld
```

## Development Commands

```bash
# Open in Xcode
open thnk.xcodeproj

# Build from command line
xcodebuild -project thnk.xcodeproj -scheme thnk build

# Run tests
xcodebuild test -project thnk.xcodeproj -scheme thnk -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build
xcodebuild clean -project thnk.xcodeproj -scheme thnk
```

## Environment Configuration

### Required Environment Variables
- `CLAUDE_API_KEY`: Anthropic Claude API key for emotional analysis

### API Integration Details
- **Model**: claude-sonnet-4-20250514
- **Endpoint**: https://api.anthropic.com/v1/messages
- **Privacy**: Only sends transcript + minimal context, no user identifiers
- **Timeout**: 30 seconds request, 60 seconds resource

## Core Features Implementation

### Voice Recording Flow
1. **AudioManager** handles AVAudioSession setup and recording
2. **Haptic feedback** with 528Hz start tone, 396Hz end tone
3. **Real-time level monitoring** during recording
4. **File storage** in app documents directory

### Speech Processing
- **On-device transcription** using iOS Speech Framework
- **Privacy-first** - no audio data leaves device
- **Emotional speech patterns** - configured for dictation mode
- **Permission handling** with graceful fallbacks

### AI Analysis Pipeline
- **Claude API integration** with structured prompts
- **Conversational tone** - responds as "older, wiser friend"
- **Christian perspective** influenced by Paul David Tripp/Tim Keller approach
- **Pattern recognition** using previous entry context
- **JSON response parsing** with error handling

### Data Persistence
- **Core Data** with encryption at rest
- **Minimal storage** - summaries and emotions, not full transcripts
- **Efficient queries** for pattern analysis
- **No iCloud sync** by design for privacy

## Key Design Principles

### Privacy & Security
- **On-device processing** for speech-to-text
- **Minimal API calls** - only transcript + context to Claude
- **No user tracking** or analytics
- **Local data encryption**
- **No permanent server storage**

### User Experience
- **Single-button interface** for recording
- **Zen-like animations** with breathing pulse effects
- **Progressive disclosure** - analysis appears word by word
- **Cycling suggestions** every 5 seconds
- **Haptic feedback** for all interactions

### Emotional Intelligence
- **Pattern recognition** across daily/weekly/monthly timeframes
- **Contextual references** to previous entries
- **Actionable suggestions** with appropriate icons
- **Emotional trajectory** tracking with insights

## Testing Considerations

### Unit Tests Focus On
- Audio recording/playback functionality
- Speech-to-text accuracy with various inputs
- Claude API response parsing
- Core Data operations and queries
- Pattern recognition algorithms

### Manual Testing Scenarios
- Permission flows (microphone, speech recognition)
- Network connectivity handling
- Background/foreground transitions during recording
- Long voice notes and processing timeouts
- Emotional pattern edge cases

## Common Development Tasks

### Adding New Emotions
1. Update `EmotionIndicator` color mapping in `AnalysisView.swift`
2. Enhance trigger identification in `PatternService.swift`
3. Test Claude prompt responses for new emotion types

### Modifying AI Prompt
- Update `buildAnalysisPrompt()` in `ClaudeService.swift`
- Test response parsing with new prompt structure
- Validate JSON format consistency

### Extending Pattern Analysis
- Add new pattern types in `EmotionPattern.swift`
- Implement analysis logic in `PatternService.swift`
- Update UI to display new pattern insights

## Privacy Compliance Notes

- **No PII collection** - only emotional summaries stored
- **Transparent permissions** - clear usage descriptions
- **User control** - manual recording triggers only
- **Data minimization** - efficient API usage with minimal context
- **Local encryption** - all stored data encrypted at rest

## Performance Targets

- **Recording start**: < 200ms response time
- **Speech processing**: < 3 seconds for 30-second recording
- **AI analysis**: < 5 seconds (network dependent)
- **Pattern analysis**: < 1 second for daily patterns
- **App launch**: < 2 seconds to ready state