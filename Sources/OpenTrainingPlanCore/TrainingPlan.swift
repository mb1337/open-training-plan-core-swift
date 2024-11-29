import Foundation
import Yams

/// Represents a structured training plan consisting of multiple workouts
public struct TrainingPlan: Codable {
    /// Name of the training plan
    public let name: String
    
    /// Detailed description of the plan
    public let description: String?
    
    /// Optional author of the plan
    public let author: String?
    
    public var zoneSystem: ZoneSystem?
    
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
        
        init(_ week: _TrainingPlan.Week) {
            self.notes = week.notes
            self.days = week.days.map { .init($0) }
        }
    }
    
    /// Represents a day in the training week
    public struct Day: Codable, RemoteResolvable {
        /// Workouts scheduled for this day
        public let workouts: [ScheduledWorkout]
        
        /// Notes for the day
        public let notes: String?
        
        init(_ day: _TrainingPlan.Day) {
            self.notes = day.notes
            self.workouts = day.workouts.map { .init($0) }
        }
    }
    
    public init(from data: Data, using decoder: DataDecoder) async throws {
        self = try await .init(from: data, using: decoder, resolver: DefaultRemoteResolver())
    }
    
    init(from data: Data, using decoder: DataDecoder, resolver: RemoteResolver) async throws {
        let remoteDecoder = RemoteDecoder(decoder: decoder, userInfo: [.trainingContext: TrainingContext()], resolver: resolver)
        let plan: _TrainingPlan = try remoteDecoder.decode(data: data)
        try await plan.resolve(using: remoteDecoder)
        self = .init(plan)
    }
    
    init(_ plan: _TrainingPlan) {
        self.name = plan.name
        self.author = plan.author
        self.description = plan.description
        self.tags = plan.tags
        self.zoneSystem = plan.zoneSystem
        self.weeks = plan.weeks.map { .init($0) }
    }
}

/// Internal implementation
struct _TrainingPlan: Codable, RemoteResolvable {
    /// Name of the training plan
    let name: String
    
    /// Detailed description of the plan
    let description: String?
    
    /// Optional author of the plan
    let author: String?
    
    @RemoteResource var zoneSystem: ZoneSystem?
    
    /// Training weeks
    let weeks: [Week]
    
    /// Optional tags for categorization
    let tags: [String]?
    
    /// Represents a week in the training plan
    struct Week: Codable, RemoteResolvable {
        /// Days in the week
        let days: [Day]
        
        /// Notes for the week
        let notes: String?
    }
    
    /// Represents a day in the training week
    struct Day: Codable, RemoteResolvable {
        /// Workouts scheduled for this day
        let workouts: [_ScheduledWorkout]
        
        /// Notes for the day
        let notes: String?
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        _zoneSystem = try container.decodeIfPresent(RemoteResource<ZoneSystem>.self, forKey: .zoneSystem) ?? .init()
        weeks = try container.decode([Week].self, forKey: .weeks)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        if let context = decoder.userInfo[.trainingContext] as? TrainingContext {
            context.setZoneSystem(_zoneSystem)
        }
    }
}
