import SwiftUI

struct LoadingSplashView: View {
    @State private var imageOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Full bleed splash image
            Image("Splash")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .opacity(imageOpacity)
        }
        .onAppear {
            // Simple fade-in animation
            withAnimation(.easeOut(duration: 0.4)) {
                imageOpacity = 1.0
            }
        }
    }
}

#Preview {
    LoadingSplashView()
}
