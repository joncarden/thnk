import SwiftUI

struct LoadingSplashView: View {
    @State private var imageOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Clean background matching app theme
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Simple splash image - clean and centered
            Image("splash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(imageOpacity)
        }
        .onAppear {
            // Simple fade-in animation for the splash image
            withAnimation(.easeOut(duration: 0.4)) {
                imageOpacity = 1.0
            }
        }
    }
}

#Preview {
    LoadingSplashView()
}
