import SwiftUI

struct RecordingView: View {
    let isRecording: Bool
    let isProcessing: Bool
    let hasAnalysis: Bool
    let onRecordingToggle: () -> Void
    let onFreshStart: () -> Void
    let dataStartDate: Date?
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
    
    private let buttonSize: CGFloat = 120
    private let pulseAnimationDuration: Double = 1.2
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Group {
            if hasAnalysis && !isRecording && !isProcessing {
                // Minimal thnk again button
                Button(action: onRecordingToggle) {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("thnk again")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.3), value: hasAnalysis)
            } else {
                // Original large circular button
                ZStack {
                    // Outer pulse ring (only visible when recording)
                    if isRecording {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: buttonSize * pulseScale, height: buttonSize * pulseScale)
                            .opacity(pulseOpacity)
                            .animation(
                                .easeInOut(duration: pulseAnimationDuration)
                                .repeatForever(autoreverses: true),
                                value: pulseScale
                            )
                    }
                    
                    // Main recording button
                    Button(action: onRecordingToggle) {
                        Circle()
                            .fill(buttonColor)
                            .frame(width: buttonSize, height: buttonSize)
                            .overlay(
                                Image(systemName: buttonIcon)
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
                    .disabled(isProcessing)
                }
                .onAppear {
                    if isRecording {
                        startPulseAnimation()
                    }
                }
                .onChange(of: isRecording) { recording in
                    if recording {
                        startPulseAnimation()
                    } else {
                        stopPulseAnimation()
                    }
                }
            }
            }
            
            Spacer()
            
            // Fresh Start button and date - only on main recording page (no analysis)
            if !hasAnalysis && !isRecording && !isProcessing {
                VStack(spacing: 8) {
                    Button(action: onFreshStart) {
                        Text("fresh start")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.6))
                            .underline()
                    }
                    
                    if let startDate = dataStartDate {
                        Text("data since \(formatDate(startDate))")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private var buttonColor: Color {
        if isProcessing {
            return Color.gray.opacity(0.6)
        } else if isRecording {
            return Color.red
        } else {
            return Color.gray.opacity(0.8)
        }
    }
    
    private var buttonIcon: String {
        if isProcessing {
            return "waveform.circle"
        } else if isRecording {
            return "stop.fill"
        } else {
            return "mic.fill"
        }
    }
    
    private func startPulseAnimation() {
        pulseScale = 1.4
        pulseOpacity = 0.0
    }
    
    private func stopPulseAnimation() {
        pulseScale = 1.0
        pulseOpacity = 1.0
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInYesterday(date) {
            return "yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        RecordingView(isRecording: false, isProcessing: false, hasAnalysis: false, onRecordingToggle: {}, onFreshStart: {}, dataStartDate: Date())
        RecordingView(isRecording: true, isProcessing: false, hasAnalysis: false, onRecordingToggle: {}, onFreshStart: {}, dataStartDate: nil)
        RecordingView(isRecording: false, isProcessing: true, hasAnalysis: false, onRecordingToggle: {}, onFreshStart: {}, dataStartDate: nil)
        RecordingView(isRecording: false, isProcessing: false, hasAnalysis: true, onRecordingToggle: {}, onFreshStart: {}, dataStartDate: nil)
    }
    .padding()
}