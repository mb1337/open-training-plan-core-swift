
/// Represents a workout scheduled in the training plan
public struct ScheduledWorkout: Codable {
    /// Workout template
    public let template: WorkoutTemplate
    
    /// Alternate workouts
    public let alternates: [WorkoutTemplate]?
    
    /// Target volume as absolute or percentage
    public let targetVolume: TargetVolume?
    
    /// Optional notes for this instance of the workout
    public let notes: String?
    
    init(_ workout: _ScheduledWorkout) {
        self.template = .init(workout.template!)
        self.alternates = workout.alternates?.map { .init($0) }
        self.targetVolume = workout.targetVolume
        self.notes = workout.notes
    }
}

/// Internal implementation
struct _ScheduledWorkout: Codable, RemoteResolvable {
    /// Reference to the workout
    @RemoteResource var template: _WorkoutTemplate?
    
    /// Alternate workouts
    @RemoteResourceList var alternates: [_WorkoutTemplate]?
    
    /// Target volume as absolute or percentage
    let targetVolume: TargetVolume?
    
    /// Optional notes for this instance of the workout
    let notes: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._template = try container.decode(RemoteResource<_WorkoutTemplate>.self, forKey: .template)
        self._alternates = try container.decodeIfPresent(RemoteResourceList<_WorkoutTemplate>.self, forKey: .alternates) ?? .init(nil)
        self.targetVolume = try container.decodeIfPresent(TargetVolume.self, forKey: .targetVolume)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}
