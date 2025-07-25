import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var audioManager = AudioManager()
    @StateObject private var speechService = SpeechService()
    @StateObject private var claudeService = ClaudeService()
    
    @State private var currentTranscript = ""
    @State private var analysisResult: AnalysisResult?
    @State private var isProcessing = false
    @State private var showingPermissionAlert = false
    @State private var showingLoadingSplash = true
    @State private var showingSplash = !UserDefaults.standard.bool(forKey: "hasSeenSplash")
    @State private var processingHapticTimer: Timer?
    @State private var showingFreshStartConfirmation = false
    @State private var dataStartDate: Date?
    
    var body: some View {
        ZStack {
            if showingLoadingSplash {
                LoadingSplashView()
                    .transition(AnyTransition.opacity)
            } else if showingSplash {
                SplashView {
                    handleSplashContinue()
                }
                .transition(AnyTransition.opacity)
            } else {
                mainContentView
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showingLoadingSplash)
        .animation(.easeInOut(duration: 0.8), value: showingSplash)
        .onAppear {
            loadDataStartDate()
            // Show loading splash for appropriate duration, then transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                showingLoadingSplash = false
            }
        }
        .alert("Fresh Start", isPresented: $showingFreshStartConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                performFreshStart()
            }
        } message: {
            Text("This will permanently delete all your emotional entries and start completely fresh. This cannot be undone.")
        }
    }
    
    private var mainContentView: some View {
        ZStack {
            // Minimalist background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top recording button (when analysis is shown)
                if analysisResult != nil {
                    HStack {
                        Spacer()
                        RecordingView(
                            isRecording: audioManager.isRecording,
                            isProcessing: isProcessing,
                            hasAnalysis: analysisResult != nil,
                            onRecordingToggle: handleRecordingToggle,
                            onFreshStart: { showingFreshStartConfirmation = true },
                            dataStartDate: dataStartDate
                        )
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
                
                // Main content area
                if analysisResult != nil {
                    // Analysis display (takes full remaining space)
                    if let result = analysisResult {
                        AnalysisView(result: result)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.8), value: analysisResult?.id)
                    }
                } else {
                    // Centered recording interface (original layout)
                    VStack(spacing: 40) {
                        Spacer()
                        
                        if isProcessing {
                            ProcessingView()
                                .transition(.opacity)
                        } else {
                            RecordingView(
                                isRecording: audioManager.isRecording,
                                isProcessing: isProcessing,
                                hasAnalysis: analysisResult != nil,
                                onRecordingToggle: handleRecordingToggle,
                                onFreshStart: { showingFreshStartConfirmation = true },
                                dataStartDate: dataStartDate
                            )
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                
                Spacer(minLength: 0)
            }
        }
        .onAppear {
            if !showingSplash {
                requestPermissions()
            }
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("thnk needs microphone access to record your emotional voice notes for analysis.")
        }
    }
    
    private func handleSplashContinue() {
        UserDefaults.standard.set(true, forKey: "hasSeenSplash")
        showingSplash = false
        requestPermissions()
    }
    
    private func requestPermissions() {
        speechService.requestSpeechPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func handleRecordingToggle() {
        if audioManager.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Reset previous state
        currentTranscript = ""
        analysisResult = nil
        isProcessing = false
        
        audioManager.startRecording()
    }
    
    private func stopRecording() {
        audioManager.stopRecording()
        isProcessing = true
        
        // Start pulsing haptic feedback during processing
        startProcessingHaptics()
        
        // Process the recorded audio
        Task {
            await processRecording()
        }
    }
    
    @MainActor
    private func processRecording() async {
        guard let audioURL = audioManager.lastRecordingURL else {
            stopProcessingHaptics()
            isProcessing = false
            return
        }
        
        do {
            // Speech-to-text processing
            let transcript = try await speechService.transcribeAudio(from: audioURL)
            currentTranscript = transcript
            
            print("📝 Transcript received successfully")
            
            // Validate transcript is not empty
            guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("Empty transcript received")
                cleanupAudioFile(audioURL)
                stopProcessingHaptics()
                isProcessing = false
                return
            }
            
            // Fetch previous entries for pattern recognition
            let previousEntries = await fetchRecentEntries()
            
            // AI analysis with context
            let result = try await claudeService.analyzeEmotion(transcript: transcript, previousEntries: previousEntries)
            
            // Validate analysis result
            guard !result.analysis.isEmpty else {
                print("Empty analysis received")
                cleanupAudioFile(audioURL)
                stopProcessingHaptics()
                isProcessing = false
                return
            }
            
            // Save to Core Data
            await saveEmotionalEntry(transcript: transcript, result: result)
            
            // Clean up audio file for privacy
            cleanupAudioFile(audioURL)
            
            // Update UI
            withAnimation {
                analysisResult = result
                stopProcessingHaptics()
                isProcessing = false
            }
            
        } catch {
            print("Error processing recording: \(error)")
            // Clean up audio file even on error
            cleanupAudioFile(audioURL)
            stopProcessingHaptics()
            isProcessing = false
            
            // Show specific error information
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
            } else if let speechError = error as? SpeechServiceError {
                switch speechError {
                case .recognizerNotAvailable:
                    print("🎤 Speech recognition not available. Make sure you're on a physical device with microphone permissions.")
                case .speechServiceUnavailable:
                    print("🔧 Speech service temporarily unavailable. This happens when iOS speech recognition is overloaded. The app automatically retries, but you can also try again in a moment.")
                case .transcriptionFailed:
                    print("🗣️ Could not transcribe audio. Try speaking more clearly or in a quieter environment.")
                case .audioFileNotFound:
                    print("📁 Audio recording file not found.")
                }
            } else {
                print("❌ Unexpected error: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchRecentEntries() async -> [EmotionalEntry] {
        return await viewContext.perform {
            let request: NSFetchRequest<EmotionalEntry> = EmotionalEntry.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EmotionalEntry.timestamp, ascending: false)]
            request.fetchLimit = 10 // Get last 10 entries for pattern recognition
            
            do {
                return try viewContext.fetch(request)
            } catch {
                print("Error fetching previous entries: \(error)")
                return []
            }
        }
    }
    
    private func saveEmotionalEntry(transcript: String, result: AnalysisResult) async {
        await viewContext.perform {
            let entry = EmotionalEntry(context: viewContext)
            entry.id = UUID()
            entry.timestamp = Date()
            entry.transcript = transcript
            entry.primaryEmotion = result.primaryEmotion
            entry.summary = result.summary
            entry.analysis = result.analysis
            entry.suggestions = result.suggestions.joined(separator: "|")
            
            try? viewContext.save()
        }
    }
    
    private func startProcessingHaptics() {
        // Initial gentle haptic when processing starts
        let initialHaptic = UIImpactFeedbackGenerator(style: .light)
        initialHaptic.prepare()
        initialHaptic.impactOccurred(intensity: 0.6)
        
        // Start pulsing haptics every 2 seconds
        processingHapticTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let pulseHaptic = UIImpactFeedbackGenerator(style: .light)
            pulseHaptic.prepare()
            pulseHaptic.impactOccurred(intensity: 0.4)
        }
    }
    
    private func stopProcessingHaptics() {
        processingHapticTimer?.invalidate()
        processingHapticTimer = nil
        
        // Final success haptic when processing completes
        let completionHaptic = UIImpactFeedbackGenerator(style: .medium)
        completionHaptic.prepare()
        completionHaptic.impactOccurred(intensity: 0.7)
    }
    
    private func cleanupAudioFile(_ audioURL: URL) {
        do {
            try FileManager.default.removeItem(at: audioURL)
            print("🗑️ Audio file cleaned up for privacy")
        } catch {
            print("⚠️ Failed to cleanup audio file: \(error)")
        }
    }
    
    private func performFreshStart() {
        Task {
            await deleteAllEmotionalEntries()
            
            // Update fresh start date
            UserDefaults.standard.set(Date(), forKey: "freshStartDate")
            
            // Clear UI state
            await MainActor.run {
                currentTranscript = ""
                analysisResult = nil
                isProcessing = false
                dataStartDate = Date() // Fresh start date becomes new data start
                print("🆕 Fresh start completed - all data cleared")
            }
        }
    }
    
    private func deleteAllEmotionalEntries() async {
        await viewContext.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = EmotionalEntry.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try viewContext.execute(deleteRequest)
                try viewContext.save()
                print("🗑️ All emotional entries deleted")
            } catch {
                print("❌ Failed to delete entries: \(error)")
            }
        }
    }
    
    private func loadDataStartDate() {
        Task {
            // Check if there's a fresh start date
            if let freshStartDate = UserDefaults.standard.object(forKey: "freshStartDate") as? Date {
                await MainActor.run {
                    dataStartDate = freshStartDate
                }
            } else {
                // Get earliest entry date
                let earliestDate = await fetchEarliestEntryDate()
                await MainActor.run {
                    dataStartDate = earliestDate
                }
            }
        }
    }
    
    private func fetchEarliestEntryDate() async -> Date? {
        await withCheckedContinuation { continuation in
            viewContext.perform {
                let fetchRequest: NSFetchRequest<EmotionalEntry> = EmotionalEntry.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \EmotionalEntry.timestamp, ascending: true)]
                fetchRequest.fetchLimit = 1
                
                do {
                    let entries = try viewContext.fetch(fetchRequest)
                    continuation.resume(returning: entries.first?.timestamp)
                } catch {
                    print("Failed to fetch earliest entry: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}