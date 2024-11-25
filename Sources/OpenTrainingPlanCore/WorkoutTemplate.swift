import Foundation

/// Represents a structured workout
public struct WorkoutTemplate: Codable, RemoteResolvable {
    /// Name of the workout
    public let name: String
    
    /// Detailed description of the workout
    public let description: String?
    
    /// Optional warmup period
    public let warmup: WorkoutMeasure?
    
    /// Main segments
    public let segments: [WorkoutSegment]
    
    /// Optional cooldown period
    public let cooldown: WorkoutMeasure?
    
    /// Tags for categorization
    public let tags: [String]?
}
