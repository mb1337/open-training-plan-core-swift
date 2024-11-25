import Foundation

/// Represents a structured training plan consisting of multiple workouts
public struct TrainingPlan: Codable, RemoteResolvable {
    /// Name of the training plan
    public let name: String
    
    /// Detailed description of the plan
    public let description: String
    
    /// Optional author of the plan
    public let author: String?
    
    /// Training weeks
    public let weeks: [Week]
    
    /// Optional tags for categorization
    public let tags: [String]?
    
    /// Represents a week in the training plan
    public struct Week: Codable, RemoteResolvable {
        /// Days in the week
        public let days: [Day]
        
        /// Notes for the week
        public let notes: String?
    }
    
    /// Represents a day in the training week
    public struct Day: Codable, RemoteResolvable {
        /// Workouts scheduled for this day
        public let workouts: [ScheduledWorkout]
        
        /// Notes for the day
        public let notes: String?
    }
}
