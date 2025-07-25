import SwiftUI

struct SplashView: View {
    @State private var textOpacity: Double = 0.0
    @State private var buttonOpacity: Double = 0.0
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Minimalist background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App icon with subtle emphasis
                VStack(spacing: 16) {
                    // Use splash icon from bundle
                    Image("splash-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 4, height: 4)
                }
                .opacity(textOpacity)
                
                Spacer()
                
                // Main message
                VStack(spacing: 24) {
                    Text("here to help you thnk.")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text("share your thoughts, big and small, and we'll share ours.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                    
                    Text("for the sake of privacy, all of your data will only be stored locally on this device.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineSpacing(2)
                        .padding(.horizontal, 20)
                }
                .opacity(textOpacity)
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Continue button
                Button(action: onContinue) {
                    Text("continue")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                }
                .opacity(buttonOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Gentle fade-in animation
            withAnimation(.easeOut(duration: 1.0)) {
                textOpacity = 1.0
            }
            
            // Delayed button appearance
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                buttonOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView {
        print("Continue tapped")
    }
}
