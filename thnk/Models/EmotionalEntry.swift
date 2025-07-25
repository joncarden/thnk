import Foundation
import CoreData

@objc(EmotionalEntry)
public class EmotionalEntry: NSManagedObject, Identifiable {
    
}

extension EmotionalEntry {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmotionalEntry> {
        return NSFetchRequest<EmotionalEntry>(entityName: "EmotionalEntry")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var transcript: String?
    @NSManaged public var primaryEmotion: String?
    @NSManaged public var summary: String?
    @NSManaged public var analysis: String?
    @NSManaged public var suggestions: String? // Stored as pipe-separated values
    
    // Computed property for suggestions array
    public var suggestionsArray: [String] {
        get {
            return suggestions?.components(separatedBy: "|").filter { !$0.isEmpty } ?? []
        }
        set {
            suggestions = newValue.joined(separator: "|")
        }
    }
    
    // Convenience initializer
    convenience init(context: NSManagedObjectContext, transcript: String, result: AnalysisResult) {
        self.init(context: context)
        self.id = UUID()
        self.timestamp = Date()
        self.transcript = transcript
        self.primaryEmotion = result.primaryEmotion
        self.summary = result.summary
        self.analysis = result.analysis
        self.suggestionsArray = result.suggestions
    }
}

// MARK: - Fetch Requests

extension EmotionalEntry {
    
    static func fetchTodaysEntries() -> NSFetchRequest<EmotionalEntry> {
        let request = fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EmotionalEntry.timestamp, ascending: true)]
        
        return request
    }
    
    static func fetchRecentEntries(limit: Int = 10) -> NSFetchRequest<EmotionalEntry> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EmotionalEntry.timestamp, ascending: false)]
        request.fetchLimit = limit
        
        return request
    }
    
    static func fetchEntriesByEmotion(_ emotion: String) -> NSFetchRequest<EmotionalEntry> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "primaryEmotion == %@", emotion)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EmotionalEntry.timestamp, ascending: false)]
        
        return request
    }
    
    static func fetchEntriesInDateRange(from startDate: Date, to endDate: Date) -> NSFetchRequest<EmotionalEntry> {
        let request = fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EmotionalEntry.timestamp, ascending: true)]
        
        return request
    }
}