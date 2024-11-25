
/// Represents a workout scheduled in the training plan
public struct ScheduledWorkout: Codable, RemoteResolvable {
    /// Reference to the workout
    @RemoteResource public var template: WorkoutTemplate?
    
    /// Alternate workouts
    @RemoteResourceList public var alternates: [WorkoutTemplate]?
    
    /// Target volume as absolute or percentage
    public let targetVolume: TargetVolume?
    
    /// Optional notes for this instance of the workout
    public let notes: String?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._template = try container.decode(RemoteResource<WorkoutTemplate>.self, forKey: .template)
        self._alternates = try container.decodeIfPresent(RemoteResourceList<WorkoutTemplate>.self, forKey: .alternates) ?? .init(nil)
        self.targetVolume = try container.decodeIfPresent(TargetVolume.self, forKey: .targetVolume)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}
