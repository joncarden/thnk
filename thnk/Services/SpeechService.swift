import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechService: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var isAvailable = false
    
    override init() {
        super.init()
        checkAvailability()
    }
    
    private func checkAvailability() {
        speechRecognizer?.delegate = self
        isAvailable = speechRecognizer?.isAvailable ?? false
    }
    
    func requestSpeechPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    completion(true)
                case .denied, .restricted, .notDetermined:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    func transcribeAudio(from url: URL) async throws -> String {
        guard speechRecognizer?.isAvailable == true else {
            throw SpeechServiceError.recognizerNotAvailable
        }
        
        // Check if audio file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SpeechServiceError.audioFileNotFound
        }
        
        // Retry logic for speech service errors
        var lastError: Error?
        for attempt in 1...3 {
            do {
                return try await performTranscription(from: url)
            } catch SpeechServiceError.speechServiceUnavailable {
                lastError = SpeechServiceError.speechServiceUnavailable
                if attempt < 3 {
                    let delay = TimeInterval(attempt * 2) // 2, 4 seconds
                    print("🎤 Speech service unavailable, retrying in \(delay) seconds (attempt \(attempt)/3)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            } catch {
                throw error
            }
        }
        
        throw lastError ?? SpeechServiceError.transcriptionFailed
    }
    
    private func performTranscription(from url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = true // Enable to capture longer content
            request.taskHint = .dictation
            
            // Set context for longer, more detailed speech
            request.contextualStrings = ["emotional", "feelings", "thoughts", "reflection", "journal"]
            
            // Configure for better transcription quality
            if #available(iOS 16.0, *) {
                request.addsPunctuation = true
                request.requiresOnDeviceRecognition = false // Allow server processing for better accuracy
            }
            
            // No time limit - let user record as long as they want
            
            recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
                guard !hasResumed else { return }
                
                // Debug: Log partial results to understand timing
                if let result = result, !result.isFinal {
                    print("🎤 Partial transcription: \(result.bestTranscription.formattedString.count) characters")
                }
                
                if let error = error {
                    hasResumed = true
                    // Handle specific speech recognition errors
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101 {
                        continuation.resume(throwing: SpeechServiceError.speechServiceUnavailable)
                    } else {
                        continuation.resume(throwing: SpeechServiceError.transcriptionFailed)
                    }
                    return
                }
                
                if let result = result, result.isFinal {
                    hasResumed = true
                    let transcript = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Debug: Log transcript length
                    print("🎤 Transcription complete: \(transcript.count) characters")
                    
                    // Ensure we don't return empty transcripts
                    if transcript.isEmpty {
                        continuation.resume(throwing: SpeechServiceError.transcriptionFailed)
                    } else {
                        continuation.resume(returning: transcript)
                    }
                }
            }
        }
    }
    
    func stopRecognition() {
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
    }
}

extension SpeechService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            isAvailable = available
        }
    }
}

enum SpeechServiceError: LocalizedError {
    case recognizerNotAvailable
    case audioFileNotFound
    case transcriptionFailed
    case speechServiceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognition is not available"
        case .audioFileNotFound:
            return "Audio file not found"
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .speechServiceUnavailable:
            return "Speech recognition service is temporarily unavailable"
        }
    }
}