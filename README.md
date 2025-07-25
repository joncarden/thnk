# thnk - Emotional Companion iOS App

A minimalist iOS app that serves as an always-available emotional companion, allowing users to process feelings through voice in real-time throughout their day.

## Core Value Proposition

- **Immediate emotional processing** - Capture and process feelings in 30 seconds
- **AI-powered insight** - Receive thoughtful analysis and concrete next steps powered by Claude
- **Privacy-focused design** - Minimal data transmission, no permanent storage on servers
- **Pattern recognition** - Track emotional trajectories throughout the day
- **Zen simplicity** - Ultra-minimalist interface that reduces friction to near zero

## Technical Stack

- **Platform**: iOS 16.0+
- **Framework**: SwiftUI
- **Language**: Swift 5.9+
- **AI Integration**: Claude API (Anthropic)
- **Speech Processing**: iOS Speech Framework (on-device)
- **Data Storage**: Core Data with encryption
- **Audio**: AVAudioSession

## Project Structure

```
thnk/
├── thnk/
│   ├── App/
│   │   ├── thnkApp.swift           # Main app entry point
│   │   └── ContentView.swift         # Main interface
│   ├── Views/
│   │   ├── RecordingView.swift       # Voice recording interface
│   │   ├── AnalysisView.swift        # Emotional analysis display
│   │   └── SuggestionView.swift      # Actionable suggestions
│   ├── Services/
│   │   ├── AudioManager.swift        # Audio recording & playback
│   │   ├── SpeechService.swift       # Speech-to-text processing
│   │   ├── ClaudeService.swift       # AI analysis integration
│   │   └── PatternService.swift      # Emotional pattern recognition
│   ├── Models/
│   │   ├── EmotionalEntry.swift      # Core data model
│   │   ├── AnalysisResult.swift      # AI response structure
│   │   └── EmotionPattern.swift      # Pattern tracking model
│   ├── Core Data/
│   │   └── thnkDataModel.xcdatamodeld
│   └── Resources/
│       ├── Info.plist
│       └── Sounds/
│           ├── start-528hz.aiff
│           └── end-396hz.aiff
├── thnkTests/
└── thnkUITests/
```

## Features

### MVP Features
- ✅ One-Touch Voice Recording
- ✅ Voice-to-Text Processing (on-device)
- ✅ Emotional Analysis (Claude API)
- ✅ Pattern Recognition
- ✅ Suggestion Engine

### Privacy & Security
- **No Network Calls**: App functions with minimal API calls
- **No Analytics**: Zero tracking or telemetry
- **Local Storage**: All data encrypted at rest
- **No Accounts**: No sign-up, no user IDs
- **Minimal Permissions**: Microphone only

## Development Setup

1. Open thnk.xcodeproj in Xcode 15.0+
2. Set your development team in project settings
3. Add Claude API key to environment variables
4. Build and run on iOS 16.0+ device or simulator

## API Integration

The app integrates with Claude API for emotional analysis while maintaining privacy:
- Only sends speech transcript and minimal context
- No user identifiers transmitted
- Previous entries summarized, not sent in full

## Build Commands

```bash
# Open in Xcode
open thnk.xcodeproj

# Build from command line
xcodebuild -project thnk.xcodeproj -scheme thnk build

# Run tests
xcodebuild test -project thnk.xcodeproj -scheme thnk -destination 'platform=iOS Simulator,name=iPhone 15'
```

## License

MIT License - Built with privacy and emotional well-being in mind.