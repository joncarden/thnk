import SwiftUI

struct ProcessingView: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3
    
    var body: some View {
        VStack(spacing: 20) {
            // Single animated breathing circle
            Circle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 50, height: 50)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
            
            // Processing text
            Text("preparing a response...")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(pulseOpacity + 0.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startBreathingAnimation()
        }
    }
    
    private func startBreathingAnimation() {
        // Single breathing animation - gentle and meditative
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.4
            pulseOpacity = 0.8
        }
    }
}

#Preview {
    ProcessingView()
        .padding()
}
