import Foundation
import AVFoundation
import Combine
import UIKit

@MainActor
class AudioManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordingLevel: Float = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession = AVAudioSession.sharedInstance()
    private var levelTimer: Timer?
    
    var lastRecordingURL: URL?
    
    private let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 22050, // Higher sample rate for better quality
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue, // Higher quality
        AVEncoderBitRateKey: 64000 // Better bit rate
    ]
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: recordingSettings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            lastRecordingURL = audioURL
            isRecording = true
            
            // Enhanced haptic feedback for recording start
            let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
            hapticFeedback.prepare()
            hapticFeedback.impactOccurred(intensity: 0.8)
            
            // Start level monitoring
            startLevelMonitoring()
            
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        
        // Enhanced haptic feedback for recording end
        let hapticFeedback = UIImpactFeedbackGenerator(style: .heavy)
        hapticFeedback.prepare()
        hapticFeedback.impactOccurred(intensity: 1.0)
        
        // Stop level monitoring
        stopLevelMonitoring()
    }
    
    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.audioRecorder?.updateMeters()
                let averagePower = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                let normalizedLevel = max(0, (averagePower + 160) / 160)
                self.recordingLevel = normalizedLevel
            }
        }
    }
    
    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        recordingLevel = 0.0
    }
    
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}