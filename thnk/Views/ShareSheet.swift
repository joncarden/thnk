import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // Configure for Notes app specifically
        controller.setValue("Emotional Reflection", forKey: "subject")
        
        // Exclude some activities that don't make sense for emotional reflections
        controller.excludedActivityTypes = [
            .postToWeibo,
            .postToVimeo,
            .postToTencentWeibo,
            .postToFlickr,
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .postToFacebook,
            .postToTwitter
        ]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}