# Search Index - Thnk iOS App

## Quick Reference by File Size

### Large Files (200+ lines)
1. **ContentView.swift** (397 lines) - Main navigation and app flow
2. **ClaudeService.swift** (370 lines) - AI integration service
3. **AnalysisView.swift** (263 lines) - Results display with emotion indicators
4. **PatternService.swift** (245 lines) - Emotional pattern analysis

### Medium Files (100-199 lines)
1. **RecordingView.swift** (171 lines) - Voice recording interface
2. **SpeechService.swift** (159 lines) - Speech-to-text conversion
3. **EmotionPattern.swift** (147 lines) - Pattern data models
4. **AudioManager.swift** (106 lines) - Audio recording/playback

### Small Files (<100 lines)
1. **SuggestionView.swift** (99 lines) - AI suggestions display
2. **SplashView.swift** (96 lines) - App launch screen
3. **EmotionalEntry.swift** (92 lines) - Core Data entity
4. **AnalysisResult.swift** (86 lines) - AI analysis data model
5. **ProcessingView.swift** (43 lines) - Processing state UI
6. **ShareSheet.swift** (41 lines) - System sharing integration
7. **ThnkApp.swift** (35 lines) - App entry point
8. **LoadingSplashView.swift** (26 lines) - Loading screen

## Search Keywords by Feature

### Audio & Recording
- **Files**: AudioManager.swift, RecordingView.swift, SpeechService.swift
- **Keywords**: AVFoundation, recording, playback, audio session, microphone
- **Classes**: AudioManager, SpeechService

### AI & Analysis
- **Files**: ClaudeService.swift, AnalysisView.swift, PatternService.swift
- **Keywords**: Claude API, emotional analysis, pattern detection, AI insights
- **Classes**: ClaudeService, PatternService
- **Models**: AnalysisResult, EmotionPattern

### User Interface
- **Files**: All View files, ContentView.swift
- **Keywords**: SwiftUI, navigation, UI components, user interaction
- **Views**: ContentView, AnalysisView, RecordingView, SplashView

### Data Management
- **Files**: ThnkApp.swift, EmotionalEntry.swift, Models/
- **Keywords**: Core Data, persistence, data models, storage
- **Classes**: PersistenceController
- **Models**: EmotionalEntry, AnalysisResult, EmotionPattern

### Error Handling
- **Files**: ClaudeService.swift, SpeechService.swift
- **Keywords**: error handling, LocalizedError, custom errors
- **Enums**: ClaudeServiceError, SpeechServiceError

## API & External Dependencies

### Claude AI Integration
- **File**: ClaudeService.swift (370 lines)
- **Endpoint**: Claude API for emotional analysis
- **Error Handling**: ClaudeServiceError enum (line 337+)

### Speech Recognition
- **File**: SpeechService.swift (159 lines)
- **Framework**: Speech framework
- **Permissions**: Microphone and speech recognition

### Audio Recording
- **File**: AudioManager.swift (106 lines)
- **Framework**: AVFoundation
- **Features**: Recording, playback, file management

## Component Relationships

### Data Flow
1. **RecordingView** → **AudioManager** → Audio file
2. **Audio file** → **SpeechService** → Text transcript
3. **Text** → **ClaudeService** → Analysis result
4. **AnalysisResult** → **AnalysisView** → User display
5. **Data** → **PatternService** → Pattern analysis

### State Management
- **ObservableObjects**: AudioManager, ClaudeService, PatternService, SpeechService
- **State Flow**: Services publish changes → Views react automatically
- **Persistence**: Core Data for long-term storage

## Development Hotspots

### Most Complex Files
1. **ContentView.swift** (397 lines) - Main app navigation
2. **ClaudeService.swift** (370 lines) - AI service integration
3. **AnalysisView.swift** (263 lines) - Complex result display
4. **PatternService.swift** (245 lines) - Pattern analysis logic

### Key Integration Points
- **ThnkApp.swift**: App lifecycle and Core Data setup
- **ContentView.swift**: Main navigation hub
- **Services/**: Business logic layer
- **Models/**: Data structure definitions

### Testing Focus Areas
- **ClaudeService**: API integration and error handling
- **AudioManager**: Recording functionality
- **SpeechService**: Speech recognition accuracy
- **PatternService**: Analysis algorithm validation